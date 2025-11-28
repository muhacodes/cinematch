from django.db import models

class User(models.Model):
    id = models.CharField(max_length=100, primary_key=True)  # clerkId or auth ID
    email = models.EmailField(unique=True)
    clerk_id = models.CharField(max_length=100, unique=True)
    age = models.IntegerField(null=True, blank=True)
    country = models.CharField(max_length=100, null=True, blank=True)
    max_age_rating = models.CharField(max_length=50, null=True, blank=True)
    preferred_langs = models.JSONField(default=list)  # ["en","es"]

    def __str__(self):
        return self.email


class Preference(models.Model):
    id = models.CharField(max_length=100, primary_key=True)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="preferences")
    genres = models.JSONField(default=list)         # ["Action","Drama"]
    mood_tags = models.JSONField(default=list)      # ["dark","intense"]
    pace = models.CharField(max_length=50, null=True, blank=True)
    violence_level = models.CharField(max_length=50, null=True, blank=True)
    runtime_pref = models.CharField(max_length=50, null=True, blank=True)

    def __str__(self):
        return f"{self.user.email} preferences"


class Movie(models.Model):
    id = models.CharField(max_length=100, primary_key=True)  # TMDB ID as string
    title = models.CharField(max_length=200)
    year = models.IntegerField(null=True, blank=True)
    genres = models.JSONField(default=list)
    language = models.CharField(max_length=50, null=True, blank=True)
    age_rating = models.CharField(max_length=20, null=True, blank=True)
    runtime = models.IntegerField(null=True, blank=True)
    overview = models.TextField(null=True, blank=True)
    poster_url = models.CharField(max_length=300, null=True, blank=True)

    def __str__(self):
        return self.title


class Favorite(models.Model):
    id = models.CharField(max_length=100, primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="favorites")
    movie = models.ForeignKey(Movie, on_delete=models.CASCADE, related_name="favorited_by")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.email} - {self.movie.title}"
