from django.urls import path
from .views import (
    TrendingView,
    movie_details_view,
    TopRatedView,
    MoviesByGenreView,
    MovieByTitleView,
    GenreListView,
    RecommendationView,
    SearchView,
    DiscoverView,
    movie_keywords_view,
    TrendingGenresView,
)

urlpatterns = [
    # Main API endpoints
    path('trending/', TrendingView.as_view(), name='trending'),
    path('movies-details/', movie_details_view.as_view(), name='movies'),
    path('movies-keywords/', movie_keywords_view.as_view(), name='movies-keywords'),
    path('trending-genres/', TrendingGenresView.as_view(), name='trending-genres'),
    path('top-rated/', TopRatedView.as_view(), name='top-rated'),
    path('by-genre/', MoviesByGenreView.as_view(), name='by-genre'),
    path('by-title/', MovieByTitleView.as_view(), name='by-title'),
    path('genres/', GenreListView.as_view(), name='genres'),
    path('recommendations/', RecommendationView.as_view(), name='recommendations'),
    
    # Legacy endpoints (for backward compatibility)
    path('search/', SearchView.as_view(), name='search'),
    path('discover/', DiscoverView.as_view(), name='discover'),
]

