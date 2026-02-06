"""DB config from env. Match db/.env. Do not set default password — use env only."""
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5432
    POSTGRES_DB: str = "edge_hmi"
    POSTGRES_USER: str = "admin"
    POSTGRES_PASSWORD: str = ""  # Must be set via env; do not hardcode
    POSTGRES_SCHEMA: str = "core"

    @property
    def database_url(self) -> str:
        return (
            f"postgresql://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}"
            f"@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        )


settings = Settings()
