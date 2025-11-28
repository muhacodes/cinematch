from .services import TMDBService


def fetch_movie_details_with_keywords(movie_ids):
    """
    Fetch full movie details including keywords for a list of movie IDs
    
    Args:
        movie_ids: list of TMDB movie IDs (integers or strings)
    
    Returns:
        list of movie detail dictionaries with keywords included
    """
    tmdb_service = TMDBService()
    movies_data = []
    
    for movie_id in movie_ids:
        try:
            # Get movie details
            movie_details = tmdb_service.get_movie_details(movie_id)
            
            # Get keywords
            keywords_data = tmdb_service.get_movie_keywords(movie_id)
            movie_details['keywords'] = keywords_data
            
            movies_data.append(movie_details)
        except Exception as e:
            # Log error but continue with other movies
            print(f"Error fetching movie {movie_id}: {e}")
            continue
    
    return movies_data


def get_genre_id_mapping():
    """
    Get a mapping of genre names to TMDB genre IDs
    
    Returns:
        dict mapping genre names (lowercase) to genre IDs
    """
    tmdb_service = TMDBService()
    genre_list = tmdb_service.get_genre_list()
    
    return {genre['name'].lower(): genre['id'] for genre in genre_list.get('genres', [])}

