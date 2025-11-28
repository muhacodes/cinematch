from rest_framework import serializers
from .models import User, Preference, Movie, Favorite


class PreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Preference
        fields = "__all__"


class MovieSerializer(serializers.ModelSerializer):
    class Meta:
        model = Movie
        fields = "__all__"


class FavoriteSerializer(serializers.ModelSerializer):
    movie = MovieSerializer(read_only=True)

    class Meta:
        model = Favorite
        fields = "__all__"


class UserSerializer(serializers.ModelSerializer):
    preferences = PreferenceSerializer(read_only=True)
    favorites = FavoriteSerializer(many=True, read_only=True)

    class Meta:
        model = User
        fields = "__all__"
