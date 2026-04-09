# MealTracker

Кроссплатформенное мобильное приложение для учёта питания с AI-распознаванием блюд по фото.

## Стек технологий

- **Мобильное приложение**: Flutter (Dart)
- **Бэкенд**: Python FastAPI
- **База данных**: SQLite (локально) + PostgreSQL (сервер)
- **AI**: Gemini 3 Flash Preview через Timeweb Cloud
- **Хостинг**: Timeweb Cloud (App Platform + AI-агент)
- **CI/CD**: GitHub Actions

## Структура проекта

```
app/                  # Flutter-приложение (Android + iOS)
backend/              # FastAPI бэкенд
scripts/scraper/      # Парсер edostavka.by
assets/database/      # Предзаполненная база продуктов
```

## Функциональность

- Дневник питания с расчётом БЖУ и калорий
- База из 5500+ готовых к употреблению продуктов (edostavka.by)
- AI-распознавание блюд по фото (Gemini 3 Flash Preview)
- Создание своих продуктов и рецептов
- Статистика и графики за неделю/месяц
- Избранное, история, копирование приёмов пищи
- Push-напоминания о приёмах пищи

## Запуск парсера

```bash
cd scripts/scraper
pip install -r requirements.txt
python scrape_edostavka.py
```
