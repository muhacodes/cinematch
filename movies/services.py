import requests
import json
import os
from django.conf import settings
from django.core.cache import cache


class TMDBService:
    """Service for interacting with TMDB API"""
    
    def __init__(self):
        self.base_url = settings.TMDB_API_BASE_URL
        self.headers = {
            "Authorization": f"Bearer {settings.TMDB_READ_ACCESS_TOKEN}",
            "accept": "application/json"
        }
    
    def _make_request(self, endpoint, params=None, use_cache=True, cache_key=None, cache_timeout=86400):
        """Make a request to TMDB API with optional caching"""
        if use_cache and cache_key:
            cached = cache.get(cache_key)
            if cached:
                return cached
        
        url = f"{self.base_url}{endpoint}"
        
        response = requests.get(url, headers=self.headers, params=params)
        response.raise_for_status()
        data = response.json()
        print(f"URL: {response.url}")
        
        if use_cache and cache_key:
            cache.set(cache_key, data, cache_timeout)
        
        return data
    
    def get_trending_movies(self, page=1, time_window=None):
        
        """Get trending movies"""
        cache_key = f"trending_movies_page_{page}_time_window_{time_window}"
        if time_window == "day":
            return self._make_request("/trending/movie/day", params={ "page": page, "without_genres": "16"}, cache_key=cache_key)
        elif time_window == "week":
            return self._make_request("/trending/movie/week", params={ "page": page, "without_genres": "16"}, cache_key=cache_key)
        else:
            return self._make_request("/trending/movie/", params={ "page": page, "without_genres": "16"}, cache_key=cache_key)
    
    def get_top_rated_movies(self, page=1):
        """Get top rated movies"""
        cache_key = f"top_rated_movies_page_{page}"
        return self._make_request("/movie/top_rated", params={"page": page, "without_genres": "16"}, cache_key=cache_key)
    
    def get_movies_by_genre(self, genre_id, page=1):
        """Get movies by genre ID"""
        cache_key = f"movies_genre_{genre_id}_page_{page}"
        return self._make_request("/discover/movie", params={
            "with_genres": genre_id,
            "page": page,
            "sort_by": "vote_average.desc",
            "vote_count.gte": 50,
            "without_genres": "16"
        }, cache_key=cache_key)
    
    def search_movie_by_title(self, query, page=1):
        """Search movies by title"""
        cache_key = f"search_movie_{query}_{page}"
        return self._make_request("/search/movie", params={
            "query": query,
            "page": page
        }, cache_key=cache_key, cache_timeout=3600)  # Cache searches for 1 hour
    
    def get_movie_details(self, movie_id):
        """Get full movie details by ID"""
        cache_key = f"movie_details_{movie_id}"
        return self._make_request(f"/movie/{movie_id}", cache_key=cache_key)
    
    def get_movie_keywords(self, movie_id):
        """Get keywords for a movie"""
        cache_key = f"movie_keywords_{movie_id}"
        return self._make_request(f"/movie/{movie_id}/keywords", cache_key=cache_key)
    
    def discover_movies(self, with_genres=None, with_keywords=None, sort_by="popularity.desc", page=1):
        """Discover movies with filters"""
        params = {
            "sort_by": sort_by,
            "page": page,
            "sort_by": "vote_average.desc",
            "vote_count.gte": 50,
            "without_genres": "16"
        }
        if with_genres:
            params["with_genres"] = ",".join(map(str, with_genres)) if isinstance(with_genres, list) else str(with_genres)
        if with_keywords:
            params["with_keywords"] = ",".join(map(str, with_keywords)) if isinstance(with_keywords, list) else str(with_keywords)
        
        cache_key = f"discover_{params.get('with_genres', '')}_{params.get('with_keywords', '')}_{sort_by}_{page}"
        return self._make_request("/discover/movie", params=params, cache_key=cache_key, cache_timeout=3600)
    
    def get_genre_list(self):
        """Get list of all genres"""
        cache_key = "genre_list"
        return self._make_request("/genre/movie/list", cache_key=cache_key, cache_timeout=86400 * 7)  # Cache for 7 days

    def get_movie_details(self, movie_id):
        """Get full movie details by ID"""
        cache_key = f"movie_details_{movie_id}"
        return self._make_request(f"/movie/{movie_id}", cache_key=cache_key)

    def get_trending_genres(self, with_genres, primary_release_year, sort_by="popularity.desc", page=1):
        """Get trending genres"""
        cache_key = f"trending_genres_{with_genres}_{primary_release_year}_{page}"
        return self._make_request("/discover/movie", params={
            "with_genres": with_genres,
            "primary_release_year": primary_release_year,
            "page": page,
            "sort_by": "vote_average.desc",
            "vote_count.gte": 50,
            "without_genres": "16"
            
        }, cache_key=cache_key)


class LLMService:
    """Service for interacting with LLM API"""
    
    def __init__(self):
        self.api_key = settings.LLM_API_KEY
        self.api_base_url = settings.LLM_API_BASE_URL
        self.model = settings.LLM_MODEL
    
    def get_recommendation_filters(self, preferences, movie_data_list):
        """
        Send preferences and movie data to LLM and get recommendation filters
        
        Args:
            preferences: dict with 'genres', 'mood', 'description'
            movie_data_list: list of movie detail dictionaries from TMDB
        
        Returns:
            dict with themes, genres, keywords, mood, and tmdbFilters
        """
        # Build the prompt
        prompt = self._build_prompt(preferences, movie_data_list)
        
        # Call LLM API
        response = self._call_llm(prompt)
        
        # Parse and return the response
        return self._parse_llm_response(response)
    
    def _build_prompt(self, preferences, movie_data_list):
        """Build the prompt for LLM"""
        # Format movie data
        movies_text = "\n".join([
            f"Movie: {movie.get('title', 'Unknown')} ({movie.get('release_date', 'Unknown')[:4] if movie.get('release_date') else 'Unknown'})\n"
            f"Genres: {', '.join([g['name'] for g in movie.get('genres', [])])}\n"
            f"Overview: {movie.get('overview', 'N/A')}\n"
            f"Keywords: {', '.join([k['name'] for k in movie.get('keywords', {}).get('keywords', [])[:10]])}\n"
            for movie in movie_data_list
        ])
        
        prompt = f"""You are an AI movie recommendation engine.

Using the user preferences and movie data below, analyze the user's taste
and return ONLY a JSON object in the following shape:

{{
  "themes": string[],
  "genres": string[],
  "keywords": string[],
  "mood": string,
  "tmdbFilters": {{
    "with_genres": number[],
    "with_keywords": number[],
    "sort_by": string
  }}
}}

User Preferences:
- Preferred Genres: {', '.join(preferences.get('genres', []))}
- Preferred Mood: {preferences.get('mood', 'Not specified')}
- Description: {preferences.get('description', 'Not provided')}

Movie Data:
{movies_text}

Return ONLY the JSON object, no additional text or explanation."""
        
        return prompt
    
    def _call_llm(self, prompt):
        """Call the LLM API"""
        url = f"{self.api_base_url}/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": self.model,
            "messages": [
                {
                    "role": "system",
                    "content": "You are a helpful assistant that returns only valid JSON."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "temperature": 0.7,
            "response_format": {"type": "json_object"}
        }
        
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        return response.json()
    
    def _parse_llm_response(self, llm_response):
        """Parse LLM response and extract JSON"""
        try:
            content = llm_response['choices'][0]['message']['content']
            # Try to parse JSON from the content
            if isinstance(content, str):
                # Sometimes LLM wraps JSON in markdown code blocks
                if '```json' in content:
                    content = content.split('```json')[1].split('```')[0].strip()
                elif '```' in content:
                    content = content.split('```')[1].split('```')[0].strip()
                return json.loads(content)
            return content
        except (KeyError, json.JSONDecodeError) as e:
            raise ValueError(f"Failed to parse LLM response: {e}")

