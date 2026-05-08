# Sprint 1 - Task 3.1

## Реализовать Descriptive SOAP Auth Builder

## Роль

Выделить infrastructure-only builder для auth/header assembly descriptive endpoint.

## Контракт

Input:

- endpoint credentials
- sender/from config
- profile-specific header options

Output:

- complete descriptive auth/header representation

## Правила

1. orchestration не знает деталей header assembly
2. client получает уже готовый auth/header object
3. builder не знает bundle/storage concerns

