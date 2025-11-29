import time
import redis
from rest_framework.throttling import BaseThrottle
from django.conf import settings
from .ip import get_client_ip

def get_redis_connection():
    redis_url = settings.CACHES['default']['LOCATION']
    return redis.Redis.from_url(redis_url)

class AnonymousRateThrottle(BaseThrottle):

    MINUTE_LIMIT = 5
    HOURLY_LIMIT = 20
    DAILY_LIMIT = 50

    # How many times can someone violate before getting banned?
    VIOLATION_THRESHOLD = 10
    BAN_DURATION = 3600  # 1 hour

    def get_cache_keys(self, request):
        ip = get_client_ip(request)

        minute_key = f"rl:ip:{ip}:minute:{int(time.time() // 60)}"
        hour_key   = f"rl:ip:{ip}:hour:{int(time.time() // 3600)}"
        day_key    = f"rl:ip:{ip}:day:{int(time.time() // 86400)}"

        violation_key = f"rl:ip:{ip}:violations"
        banned_key    = f"rl:ip:{ip}:banned"

        return minute_key, hour_key, day_key, violation_key, banned_key

    def allow_request(self, request, view):
        r = get_redis_connection()
        ip = get_client_ip(request)

        minute_key, hour_key, day_key, violation_key, banned_key = self.get_cache_keys(request)

        # 🚫 Is IP banned?
        if r.exists(banned_key):
            return False

        # Count current usage
        minute_count = r.incr(minute_key)
        hour_count   = r.incr(hour_key)
        day_count    = r.incr(day_key)

        if minute_count == 1:
            r.expire(minute_key, 60)
        if hour_count == 1:
            r.expire(hour_key, 3600)
        if day_count == 1:
            r.expire(day_key, 86400)

        # Check limits
        if (
            minute_count > self.MINUTE_LIMIT or
            hour_count > self.HOURLY_LIMIT or
            day_count > self.DAILY_LIMIT
        ):
            # Increase violation count
            violations = r.incr(violation_key)

            # Expire violation counter in 24 hours
            if violations == 1:
                r.expire(violation_key, 86400)

            # Ban if too many violations
            if violations >= self.VIOLATION_THRESHOLD:
                r.setex(banned_key, self.BAN_DURATION, 1)
                return False

            return False

        return True

    def wait(self):
        return None
