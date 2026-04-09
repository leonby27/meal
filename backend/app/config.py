from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql+asyncpg://user:password@localhost:5432/mealtracker"
    database_ssl: bool = True
    secret_key: str = "change-me-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7  # 7 days

    google_client_id: str = ""

    timeweb_ai_agent_id: str = ""
    timeweb_ai_token: str = ""
    timeweb_ai_base_url: str = "https://agent.timeweb.cloud/api/v1/cloud-ai/agents"

    max_recognitions_per_day: int = 20

    class Config:
        env_file = ".env"


settings = Settings()
