"""
Utility to get client IP address from request
"""

def get_client_ip(request):
    """
    Get the client IP address from the request
    
    Handles proxy headers like X-Forwarded-For
    """
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        # X-Forwarded-For can contain multiple IPs, get the first one
        ip = x_forwarded_for.split(',')[0].strip()
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip

