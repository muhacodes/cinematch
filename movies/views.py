from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .services import TMDBService, LLMService
from .utils import fetch_movie_details_with_keywords, get_genre_id_mapping


def health(request):
    return JsonResponse({"status": "ok"})
    
class TrendingView(APIView):
    """Get trending movies"""
    def get(self, request):
        page = request.GET.get("page", 1)
        try:
            page = int(page)
        except ValueError:
            page = 1

        time_window = request.GET.get("time_window", "week")
        if time_window not in ["day", "week"]:
            time_window = "week"

        # time_window = request.GET.get("time_window", "week")
        tmdb_service = TMDBService()
        data = tmdb_service.get_trending_movies(page=page, time_window=time_window)
        return Response(data)

class TrendingGenresView(APIView):
    # something along the lines of /discover/movie?with_genres=28&primary_release_year=2025&sort_by=popularity.desc
    """Get trending genres"""
    def get(self, request):
        with_genres = request.GET.get("with_genres", "")
        primary_release_year = request.GET.get("primary_release_year", "")
        sort_by = request.GET.get("sort_by", "popularity.desc")
        page = request.GET.get("page", 1)
        if not with_genres or not primary_release_year or not sort_by:
            return Response(
                {"error": "with_genres, primary_release_year, and sort_by parameters are required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        try:
            with_genres = int(with_genres)
            primary_release_year = int(primary_release_year)
            page = int(page)
        except ValueError:
            return Response(
                {"error": "with_genres and primary_release_year must be integers"},
                status=status.HTTP_400_BAD_REQUEST
            )
        tmdb_service = TMDBService()
        data = tmdb_service.get_trending_genres(with_genres=with_genres, primary_release_year=primary_release_year, sort_by=sort_by, page=page)
        return Response(data)


class TopRatedView(APIView):
    """Get top rated movies"""
    def get(self, request):
        page = request.GET.get("page", 1)
        try:
            page = int(page)
        except ValueError:
            page = 1
        
        tmdb_service = TMDBService()
        data = tmdb_service.get_top_rated_movies(page=page)
        return Response(data)


class movie_details_view(APIView):
    """Get movie details by ID"""
    def get(self, request):
        movie_id = request.GET.get("movie_id")
        if not movie_id:
            return Response(
                {"error": "movie_id parameter is required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        try:
            movie_id = int(movie_id)
        except ValueError:
            return Response(
                {"error": "movie_id must be an integer"},
                status=status.HTTP_400_BAD_REQUEST
            )
        tmdb_service = TMDBService()
        data = tmdb_service.get_movie_details(movie_id)
        return Response(data)

class movie_keywords_view(APIView):
    """Get movie keywords by ID"""
    def get(self, request):
        movie_id = request.GET.get("movie_id")
        tmdb_service = TMDBService()
        data = tmdb_service.get_movie_keywords(movie_id)
        return Response(data)

class MoviesByGenreView(APIView):
    """Get movies by genre ID"""
    def get(self, request):
        genre_id = request.GET.get("genre_id")
        page = request.GET.get("page", 1)
        
        if not genre_id:
            return Response(
                {"error": "genre_id parameter is required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            genre_id = int(genre_id)
            page = int(page)
        except ValueError:
            return Response(
                {"error": "genre_id and page must be integers"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        tmdb_service = TMDBService()
        data = tmdb_service.get_movies_by_genre(genre_id, page=page)
        return Response(data)


class MovieByTitleView(APIView):
    """Search movies by title"""
    def get(self, request):
        query = request.GET.get("query", "")
        page = request.GET.get("page", 1)
        
        if not query:
            return Response(
                {"error": "query parameter is required"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            page = int(page)
        except ValueError:
            page = 1
        
        tmdb_service = TMDBService()
        data = tmdb_service.search_movie_by_title(query, page=page)
        return Response(data)


class SearchView(APIView):
    """Legacy search endpoint - redirects to MovieByTitleView"""
    def get(self, request):
        # Keep for backward compatibility
        view = MovieByTitleView()
        return view.get(request)


class DiscoverView(APIView):
    """Legacy discover endpoint"""
    def get(self, request):
        genres = request.GET.get("with_genres", "")
        keywords = request.GET.get("with_keywords", "")
        sort_by = request.GET.get("sort_by", "popularity.desc")
        page = request.GET.get("page", 1)
        
        try:
            page = int(page)
        except ValueError:
            page = 1
        
        # Parse genres and keywords
        with_genres = [int(g.strip()) for g in genres.split(',') if g.strip()] if genres else None
        with_keywords = [int(k.strip()) for k in keywords.split(',') if k.strip()] if keywords else None
        
        tmdb_service = TMDBService()
        data = tmdb_service.discover_movies(
            with_genres=with_genres,
            with_keywords=with_keywords,
            sort_by=sort_by,
            page=page
        )
        return Response(data)


class GenreListView(APIView):
    """Get list of all available genres"""
    def get(self, request):
        tmdb_service = TMDBService()
        data = tmdb_service.get_genre_list()
        return Response(data)


class RecommendationView(APIView):
    """Get movie recommendations based on user preferences and liked movies"""
    
    def post(self, request):
        """
        Receive movie_ids and preferences, return recommendations
        
        Expected payload:
        {
            "movie_ids": [123, 456, 789],
            "preferences": {
                "genres": ["Action", "Thriller"],
                "mood": "Intense",
                "description": "I like smart psychological thrillers with twists."
            }
        }
        """
        movie_ids = request.data.get("movie_ids", [])
        preferences = request.data.get("preferences", {})
        
        # Validate input
        if not movie_ids:
            return Response(
                {"error": "movie_ids is required and cannot be empty"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if not isinstance(movie_ids, list):
            return Response(
                {"error": "movie_ids must be a list"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate preferences
        required_prefs = ["genres", "mood", "description"]
        for pref in required_prefs:
            if pref not in preferences:
                return Response(
                    {"error": f"preferences.{pref} is required"},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        try:
            # Fetch movie details with keywords
            movie_data_list = fetch_movie_details_with_keywords(movie_ids)
            
            if not movie_data_list:
                return Response(
                    {"error": "No valid movie data could be fetched"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Get recommendation filters from LLM
            llm_service = LLMService()
            recommendation_filters = llm_service.get_recommendation_filters(
                preferences, 
                movie_data_list
            )
            
            # Extract TMDB filters
            tmdb_filters = recommendation_filters.get("tmdbFilters", {})
            with_genres = tmdb_filters.get("with_genres", [])
            with_keywords = tmdb_filters.get("with_keywords", [])
            sort_by = tmdb_filters.get("sort_by", "popularity.desc")
            
            # Convert genre names to IDs if needed
            if with_genres and isinstance(with_genres[0], str):
                genre_mapping = get_genre_id_mapping()
                with_genres = [genre_mapping.get(genre.lower()) for genre in with_genres if genre_mapping.get(genre.lower())]
            
            # Ensure with_genres and with_keywords are lists of integers
            with_genres = [int(g) for g in with_genres if g] if with_genres else None
            with_keywords = [int(k) for k in with_keywords if k] if with_keywords else None
            
            # Discover movies using the filters
            tmdb_service = TMDBService()
            recommendations = tmdb_service.discover_movies(
                with_genres=with_genres,
                with_keywords=with_keywords,
                sort_by=sort_by,
                page=1
            )
            
            # Return recommendations along with the analysis
            return Response({
                "recommendations": recommendations,
                "analysis": {
                    "themes": recommendation_filters.get("themes", []),
                    "genres": recommendation_filters.get("genres", []),
                    "keywords": recommendation_filters.get("keywords", []),
                    "mood": recommendation_filters.get("mood", ""),
                }
            })
            
        except Exception as e:
            return Response(
                {"error": f"Failed to generate recommendations: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
