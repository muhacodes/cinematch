<<<<<<< HEAD
# CineMatch - AI-Powered Movie Recommendation API

CineMatch is a Django REST API that provides personalized movie recommendations using TMDB data and LLM-powered analysis of user preferences.

## Features

### Core API Endpoints
- 🔥 **Trending Movies** - Get currently trending movies
- ⭐ **Top Rated** - Fetch highest-rated movies
- 🎭 **Movies by Genre** - Filter movies by specific genres
- 🔍 **Search by Title** - Find movies by name
- 🎯 **AI Recommendations** - Personalized recommendations based on user taste

### Technical Features
- ✅ Redis caching for improved performance
- ✅ Rate limiting (IP-based throttling)
- ✅ CORS support for frontend integration
- ✅ Docker containerization
- ✅ AWS deployment ready
- ✅ CI/CD with GitHub Actions
- ✅ PostgreSQL support for production

## Quick Start

### Prerequisites
- Python 3.11+
- Redis
- TMDB API key
- OpenAI API key (or compatible LLM)

### Local Development

1. **Clone and setup:**
   ```bash
   git clone <your-repo>
   cd CineMatch
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

2. **Create `.env` file:**
   ```bash
   cp .env.example .env
   # Edit .env with your API keys
   ```

3. **Run migrations:**
   ```bash
   python manage.py migrate
   ```

4. **Start Redis:**
   ```bash
   # Docker
   docker run -d -p 6379:6379 redis:7-alpine
   
   # Or use local Redis
   redis-server
   ```

5. **Run server:**
   ```bash
   python manage.py runserver
   ```

6. **Test API:**
   ```bash
   curl http://localhost:8000/api/trending/
   ```

### Docker Development

```bash
docker-compose up
```

Visit: http://localhost:8000

## API Documentation

### Public Endpoints

#### 1. Get Trending Movies
```http
GET /api/trending/?page=1
```

#### 2. Get Top Rated Movies
```http
GET /api/top-rated/?page=1
```

#### 3. Get Movies by Genre
```http
GET /api/by-genre/?genre_id=28&page=1
```

#### 4. Search Movies by Title
```http
GET /api/by-title/?query=inception&page=1
```

#### 5. Get Genre List
```http
GET /api/genres/
```

#### 6. Get AI Recommendations (POST)
```http
POST /api/recommendations/
Content-Type: application/json

{
  "movie_ids": [550, 13, 680],
  "preferences": {
    "genres": ["Action", "Thriller"],
    "mood": "Intense",
    "description": "I like smart psychological thrillers with twists."
  }
}
```

**Response:**
```json
{
  "recommendations": {
    "results": [...],
    "page": 1,
    "total_pages": 100
  },
  "analysis": {
    "themes": ["psychological", "twists", "mystery"],
    "genres": ["Thriller", "Mystery"],
    "keywords": ["mind-bending", "plot-twist"],
    "mood": "dark and intense"
  }
}
```

### Rate Limiting

- **Hourly limit:** 20 requests per IP
- **Daily limit:** 50 requests per IP
- Applies to anonymous users

## Project Structure

```
CineMatch/
├── movies/                 # Main Django app
│   ├── models.py          # Database models
│   ├── views.py           # API views
│   ├── serializers.py     # DRF serializers
│   ├── services.py        # TMDB & LLM services
│   ├── utils/
│   │   ├── throttling.py  # Rate limiting
│   │   └── ip.py          # IP extraction utility
│   └── urls.py            # URL routing
├── project/               # Django project settings
│   ├── settings.py        # Configuration
│   └── urls.py            # Root URL config
├── terraform/             # AWS infrastructure
│   ├── main.tf
│   ├── vpc.tf
│   ├── ec2.tf
│   ├── rds.tf
│   └── security_groups.tf
├── .github/workflows/     # CI/CD pipelines
│   ├── deploy.yml
│   └── test.yml
├── Dockerfile.prod        # Production Docker image
├── docker-compose.yml     # Development setup
├── requirements.txt       # Python dependencies
└── DEPLOYMENT.md         # Deployment guide
```

## Environment Variables

Required environment variables:

```env
# Django
DEBUG=True
SECRET_KEY=your-secret-key
ALLOWED_HOSTS=localhost,127.0.0.1

# Database (Production)
DB_ENGINE=django.db.backends.postgresql
DB_NAME=cinematch
DB_USER=cinematch_admin
DB_PASSWORD=your-password
DB_HOST=localhost
DB_PORT=5432

# Redis
REDIS_URL=redis://localhost:6379/1

# TMDB API
TMDB_READ_ACCESS_TOKEN=your-tmdb-token

# LLM API (OpenAI or compatible)
LLM_API_KEY=your-llm-key
LLM_API_BASE_URL=https://api.openai.com/v1
LLM_MODEL=gpt-4o-mini

# CORS (Production)
CORS_ALLOWED_ORIGINS=https://yourfrontend.com
```

## Deployment

### AWS Deployment (Recommended)

Full deployment to AWS with:
- Isolated VPC
- Private RDS PostgreSQL
- Private ElastiCache Redis
- EC2 (t2.micro - cheapest)
- Separate security groups

**See [DEPLOYMENT.md](DEPLOYMENT.md) for complete guide.**

Quick deploy:
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

### CI/CD with GitHub Actions

Automatic deployment on push to `main`:
1. Builds Docker image
2. Pushes to DockerHub
3. Deploys to AWS EC2
4. Runs migrations
5. Restarts services

**Required GitHub Secrets:**
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `EC2_HOST`
- `EC2_SSH_PRIVATE_KEY`

## Architecture

### Development
```
┌──────────┐     ┌──────────┐     ┌───────────┐
│  Django  │────▶│  Redis   │     │   TMDB    │
│   8000   │     │  Cache   │────▶│    API    │
└────┬─────┘     └──────────┘     └───────────┘
     │
     │           ┌───────────┐
     └──────────▶│  OpenAI   │
                 │    LLM    │
                 └───────────┘
```

### Production (AWS)
```
          api.cinematch.muhacodes.com
                    │
                    ▼
┌────────────────────────────────────────┐
│              VPC                       │
│  ┌─────────────────────────────────┐  │
│  │   EC2 t2.micro (Public)         │  │
│  │   - Nginx + Certbot (Free SSL)  │  │
│  │   - Django (Docker)             │  │
│  │   - Redis (Docker)              │  │
│  └─────────────┬───────────────────┘  │
│                │                       │
│  ┌─────────────▼───────────────────┐  │
│  │  RDS PostgreSQL (Private)       │  │
│  │  - Only accessible from EC2     │  │
│  └─────────────────────────────────┘  │
└────────────────────────────────────────┘
```

## Cost Estimate (AWS)

**Super affordable setup!**
- **Year 1:** ~$0/month (free tier covers everything!)
- **After Year 1:** ~$20-25/month

Resources:
- EC2 t2.micro: $8-10/month (free tier: 750 hrs/month)
- RDS db.t3.micro: $12-15/month (free tier: 750 hrs/month)
- Redis: $0 (runs inside EC2!)
- SSL Certificate: $0 (Let's Encrypt!)
- Data transfer: $1-3/month

**No ElastiCache cost - Redis runs on EC2!**

## Development

### Run Tests
```bash
python manage.py test
```

### Check Linting
```bash
flake8 movies project --max-line-length=120
```

### Create Migrations
```bash
python manage.py makemigrations
python manage.py migrate
```

## Technology Stack

- **Backend:** Django 5.2, Django REST Framework 3.16
- **Cache:** Redis 7
- **Database:** PostgreSQL 15 (production), SQLite (development)
- **LLM:** OpenAI GPT-4o-mini (configurable)
- **Infrastructure:** AWS (EC2, RDS, ElastiCache, VPC)
- **IaC:** Terraform
- **CI/CD:** GitHub Actions
- **Containerization:** Docker

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
- Create an issue on GitHub
- Check [DEPLOYMENT.md](DEPLOYMENT.md) for deployment help
- Review `.github/workflows/README.md` for CI/CD help

## Acknowledgments

- [TMDB](https://www.themoviedb.org/) for movie data API
- [OpenAI](https://openai.com/) for LLM capabilities
- AWS for infrastructure

=======
# cinematch
>>>>>>> 969689f9a69dd89a892c0bc3cce4bbeb9ed93c26
