#!/bin/bash
# PostgreSQL 점검 데이터 확인 스크립트

echo "=========================================="
echo "PostgreSQL 점검 데이터 확인"
echo "=========================================="
echo ""

API_URL="http://192.168.0.18:8000"

echo "1. 전체 DB 점검 데이터 확인..."
curl -s "$API_URL/api/db-checks/data?limit=100" | python3 -m json.tool | grep -A 5 -B 5 "postgresql\|POSTGRESQL" | head -30

echo ""
echo "2. PostgreSQL 점검 데이터만 확인..."
curl -s "$API_URL/api/checks?check_type=postgresql&limit=10" | python3 -m json.tool | head -50

echo ""
echo "=========================================="
echo "확인 완료"
echo "=========================================="

