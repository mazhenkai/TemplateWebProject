#!/bin/bash
# 按白名单把 dev schema 的正式表结构同步到 prd schema。规则见 doc/doc/建表规范.md。
#
# 用法：
#   bash opt/linux/sync_tables.sh          diff（默认，只读）：列出 prd 缺少的表、两边字段差异。AI 助手可执行
#   bash opt/linux/sync_tables.sh apply    补建 prd 缺少的白名单表，再输出 diff。⚠ 只由负责人执行
#   bash opt/linux/sync_tables.sh apply -y 跳过确认（供 deploy.sh 调用）
#
# 说明：
#   - apply 只做 CREATE TABLE IF NOT EXISTS ... (LIKE ... INCLUDING ALL)，
#     不同步已有表的字段变更；diff 里列出的字段差异需手动在 prd 执行 ALTER。
#   - 只同步表结构，不同步数据。数据只允许 prd → dev。
#
# 在 config/app.env 设置：
#   TB_WHITELIST="tb_user tb_order"   要同步的表，空格分隔
#   DEV_SCHEMA=dev  PRD_SCHEMA=prd     默认即此值
#   PSQL_CMD="psql"                    数据库在容器里时如 "docker exec -i <容器名> psql -U <用户> -d <库名>"
#   使用默认 psql 时读取 DB_HOST / DB_PORT / DB_NAME / DB_USER / DB_PASSWORD
source "$(dirname "$0")/env.sh"
set -euo pipefail

MODE=${1:-diff}
YES=${2:-}
DEV_SCHEMA=${DEV_SCHEMA:-dev}
PRD_SCHEMA=${PRD_SCHEMA:-prd}
TB_WHITELIST=${TB_WHITELIST:-}

[ -z "$TB_WHITELIST" ] && { echo "未设置 TB_WHITELIST，没有要同步的表"; exit 1; }

# 名字只允许小写字母、数字、下划线，防止拼进 SQL 出问题
for name in $TB_WHITELIST "$DEV_SCHEMA" "$PRD_SCHEMA"; do
    [[ $name =~ ^[a-z][a-z0-9_]*$ ]] || { echo "非法名字：$name"; exit 1; }
done

if [ -n "${PSQL_CMD:-}" ]; then
    read -r -a PSQL <<< "$PSQL_CMD"
else
    export PGPASSWORD=${DB_PASSWORD:-}
    PSQL=(psql -h "${DB_HOST:-127.0.0.1}" -p "${DB_PORT:-5432}" -U "${DB_USER:-}" -d "${DB_NAME:-}")
fi
run_sql() { "${PSQL[@]}" -v ON_ERROR_STOP=1 -X -q "$@"; }

VALUES=$(printf "('%s')," $TB_WHITELIST); VALUES=${VALUES%,}

diff_tables() {
    echo "=== 白名单表结构对比：$DEV_SCHEMA → $PRD_SCHEMA ==="
    run_sql -A -t -F '|' <<SQL | awk -F'|' '
        $1=="missing" { printf "[%s] %-28s %s\n", ($3=="dev"?"WARN":"MISS"), $2, ($3=="dev"?"dev 中不存在，请先在 dev 建表":"prd 中不存在，apply 会补建"); bad=1; next }
        $1=="column"  { printf "[DIFF] %-28s %-20s dev=%-26s prd=%s\n", $2, $3, ($4==""?"(无)":$4), ($5==""?"(无)":$5); bad=1; next }
        END { if (!bad) print "[ OK ] 白名单表在两边一致" }'
WITH w(t) AS (VALUES $VALUES),
cols AS (
    SELECT table_schema s, table_name t, column_name c,
           data_type || CASE WHEN is_nullable = 'NO' THEN ' not null' ELSE '' END ty
    FROM information_schema.columns
    WHERE table_schema IN ('$DEV_SCHEMA', '$PRD_SCHEMA') AND table_name IN (SELECT t FROM w)
),
tabs AS (SELECT DISTINCT s, t FROM cols)
SELECT 'missing', w.t, 'dev' FROM w WHERE NOT EXISTS (SELECT 1 FROM tabs WHERE s = '$DEV_SCHEMA' AND tabs.t = w.t)
UNION ALL
SELECT 'missing', w.t, 'prd' FROM w
WHERE EXISTS (SELECT 1 FROM tabs WHERE s = '$DEV_SCHEMA' AND tabs.t = w.t)
  AND NOT EXISTS (SELECT 1 FROM tabs WHERE s = '$PRD_SCHEMA' AND tabs.t = w.t)
UNION ALL
SELECT 'column', coalesce(d.t, p.t), coalesce(d.c, p.c), coalesce(d.ty, ''), coalesce(p.ty, '')
FROM (SELECT * FROM cols WHERE s = '$DEV_SCHEMA') d
FULL JOIN (SELECT * FROM cols WHERE s = '$PRD_SCHEMA') p ON d.t = p.t AND d.c = p.c
WHERE coalesce(d.ty, '') IS DISTINCT FROM coalesce(p.ty, '')
  AND EXISTS (SELECT 1 FROM tabs WHERE s = '$DEV_SCHEMA' AND tabs.t = coalesce(d.t, p.t))
  AND EXISTS (SELECT 1 FROM tabs WHERE s = '$PRD_SCHEMA' AND tabs.t = coalesce(d.t, p.t))
ORDER BY 1, 2, 3;
SQL
}

apply_tables() {
    echo "⚠ 将在 $PRD_SCHEMA 补建缺少的白名单表：$TB_WHITELIST"
    if [ "$YES" != "-y" ]; then
        read -r -p "确认执行？输入 yes 继续：" ans
        [ "$ans" = yes ] || { echo "已取消"; exit 1; }
    fi
    run_sql <<SQL
DO \$\$
DECLARE tbl text;
BEGIN
  FOR tbl IN
    SELECT tablename FROM pg_tables
    WHERE schemaname = '$DEV_SCHEMA' AND tablename IN (SELECT t FROM (VALUES $VALUES) w(t))
  LOOP
    EXECUTE format('CREATE TABLE IF NOT EXISTS %I.%I (LIKE %I.%I INCLUDING ALL)',
                   '$PRD_SCHEMA', tbl, '$DEV_SCHEMA', tbl);
    RAISE NOTICE '已确保存在：$PRD_SCHEMA.%', tbl;
  END LOOP;
END \$\$;
SQL
    echo
}

case "$MODE" in
    diff)  diff_tables ;;
    apply) apply_tables; diff_tables ;;
    *) echo "用法：$0 [diff|apply [-y]]"; exit 1 ;;
esac
