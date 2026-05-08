# Sprint 1 - Task 3.4

## Реализовать APS Auth Builder

## Роль

Выделить WS-Security header builder для APS transport.

## Контракт

Input:

- username
- password
- ws-security config

Output:

- APS auth/header object

## Правила

1. auth builder остаётся transport infrastructure
2. orchestration не должен знать WS-Security детали
3. client получает уже собранный auth object

