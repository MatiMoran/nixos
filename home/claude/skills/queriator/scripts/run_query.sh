#!/usr/bin/env bash
# usage: bash run_query.sh <sql_file> [max_rows] [output_dir]
set -euo pipefail

SQL_FILE="${1:?usage: run_query.sh <sql_file> [max_rows] [output_dir]}"
MAX_ROWS="${2:-1000}"
PROJECT="pdme000297-jtzrug5pqtu-furyid"

# Si se pasa output_dir, guardar ahí; si no, mismo directorio que el .sql
OUTPUT_DIR="${3:-$(dirname "$SQL_FILE")}"
mkdir -p "$OUTPUT_DIR"
RESULT_FILE="$OUTPUT_DIR/$(basename "${SQL_FILE%.sql}").csv"

if grep -q "^DECLARE" "$SQL_FILE"; then
  bq query --project_id="$PROJECT" \
    --use_legacy_sql=false --format=csv --max_rows="$MAX_ROWS" \
    "$(cat "$SQL_FILE")" \
    | awk 'found{print} /; -- at \[[0-9]+:[0-9]+\]/{found=1}' > "$RESULT_FILE"
else
  bq query --project_id="$PROJECT" \
    --use_legacy_sql=false --format=csv --max_rows="$MAX_ROWS" \
    "$(cat "$SQL_FILE")" > "$RESULT_FILE"
fi

echo "Saved: $RESULT_FILE"
head -11 "$RESULT_FILE"
echo "---"
wc -l "$RESULT_FILE"
