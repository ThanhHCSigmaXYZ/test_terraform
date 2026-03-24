# GEMINI.md
# このファイルはGemini CLIが起動するたびに自動的に読み込まれます。
# Dataformコード生成に関するプロジェクトの制約とワークフローが含まれています。
# チームリーダーの承認なしに変更しないでください。

---

## プロジェクト情報
- GCPプロジェクト: ats-theme-dmo-b2bdatacolab
- 出力データセット: dev_dataform_dataset
- ソースデータセット: aiready
- リージョン: asia-northeast1
- Dataformコアバージョン: 3.0.7

---

## フォルダ構成
テーブルはプレフィックスに基づいて3つのレイヤーに分類されます：

| テーブルプレフィックス | レイヤー | 出力フォルダ |
|---|---|---|
| `raw_` | Rawレイヤー | `dataform/definitions/raw/` |
| `tmp_` | Processedレイヤー | `dataform/definitions/processed/` |
| `fct_`、`dim_` | Accessレイヤー | `dataform/definitions/access/` |

ファイルを書き込む前に、フォルダが存在しない場合は必ず作成してください。

---

## ワークフロー — 単一テーブル
以下のトリガーフレーズが使用された場合のみ実行してください。
確認を求めずに自動的に以下の手順に従ってください：

1. `docs/requirements.md` を読み込み、対象テーブルを特定する
2. `templates/sqlx_template.sqlx` をフォーマットの参考として読み込む
3. テーブルプレフィックスに基づいて正しい出力フォルダを決定する（フォルダ構成参照）
4. メインSQLXファイルを生成 → 正しいフォルダに書き込む
5. レイヤー別テストルールに従ってテストSQLXファイルを生成 → 同じフォルダに書き込む
6. 作成したファイルを報告する

### 単一テーブルのトリガーフレーズ
- "create table [テーブル名]"
- "generate dataform for [テーブル名]"
- "make [テーブル名] table"
- "generate [テーブル名]"

---

## ワークフロー — 全テーブル一括
以下のトリガーフレーズが使用された場合のみ実行してください。
確認を求めずに自動的に以下の手順に従ってください：

1. `docs/requirements.md` を読み込み、全テーブルとソーステーブルの一覧を取得する
2. `templates/sqlx_template.sqlx` をフォーマットの参考として読み込む
3. 以下のフォルダ構成を作成する：
   - `dataform/definitions/sources/`
   - `dataform/definitions/raw/`
   - `dataform/definitions/processed/`
   - `dataform/definitions/access/`
4. `docs/requirements.md` に記載された各ソーステーブル（`aiready`データセットのテーブル）について：
   - ソーステーブル1つにつき1つのdeclarationファイルを生成 → `dataform/definitions/sources/[ソーステーブル名].sqlx` に書き込む
   - 複数のソーステーブルを1つのファイルにまとめないこと
5. `docs/requirements.md` の各テーブルについて：
   - テーブルプレフィックスに基づいて正しいフォルダを決定する
   - メインSQLXファイルを生成 → 正しいフォルダに書き込む
   - レイヤー別テストルールに従ってテストSQLXファイルを生成 → 同じフォルダに書き込む
6. レイヤー別にグループ化した全作成ファイルのサマリーを報告する（declaration数も含む）

### 一括生成のトリガーフレーズ
- "generate dataform files based on tables"
- "全テーブル作成"
- "create all tables"

---

## ファイル命名規則
| ファイル | パス |
|---|---|
| 要件・仕様 | `docs/requirements.md` |
| SQLXフォーマット参考 | `templates/sqlx_template.sqlx` |
| ソースdeclaration | `dataform/definitions/sources/[ソーステーブル名].sqlx` |
| RawレイヤーSQLX | `dataform/definitions/raw/[テーブル名].sqlx` |
| Rawレイヤーテスト | `dataform/definitions/raw/[テーブル名]_test.sqlx` |
| ProcessedレイヤーSQLX | `dataform/definitions/processed/[テーブル名].sqlx` |
| Processedレイヤーテスト | `dataform/definitions/processed/[テーブル名]_test.sqlx` |
| AccessレイヤーSQLX | `dataform/definitions/access/[テーブル名].sqlx` |
| Accessレイヤーテスト | `dataform/definitions/access/[テーブル名]_test.sqlx` |

---

## SQLXコーディングルール
- テーブル生成には `templates/sqlx_template.sqlx`、テスト生成には `templates/sqlx_test_template.sqlx` の構造とフォーマットに従うこと
- typeは：メインファイルは "table"、テストファイルは "test" とすること
- schemaは常に: dev_dataform_dataset とすること
- ソーステーブルの参照には常に `${ref("テーブル名")}` を使用すること
- "table"（メインファイル）のconfigは以下のフォーマットに厳密に従うこと：
  ```
  config {
    type: "table",
    schema: "dev_dataform_dataset",
    name: "テーブル名"
  }
  ```
- BigQuery SQLの文字列には常にシングルクォートを使用すること → 'value'（"value"は不可）
- どのカラムにも `CURRENT_TIMESTAMP()` を使用しないこと — ETLメタデータカラムには代わりに `TIMESTAMP(CURRENT_DATE())` を使用すること
- パーティションキーとクラスタリングキーは `docs/requirements.md` の指定に従って適用すること
- `SELECT * EXCEPT(col1, col2, ...)` パターンは絶対に使用しないこと — 出力カラムは常に明示的にリストすること。ソースにリネームや変換が必要なカラムがある場合は、各出力カラムを名前で列挙すること。`* EXCEPT` パターンは、除外するカラムがソースの唯一のカラムである場合に失敗する（0カラム出力になる）
- BigQueryウィンドウ関数について：`LAG(col, offset)` と `LEAD(col, offset)` のデフォルト値引数は定数でなければならない — カラム参照をデフォルトとして使用しないこと。代わりに `COALESCE(LAG(col, n) OVER (...), fallback_col)` を使用すること
- JSONパース：`JSON_VALUE(col, '$.key')` を使用すること — `SAFE.JSON_EXTRACT_SCALAR(...)` は絶対に使用しないこと。`SAFE.` プレフィックスはBigQueryの組み込み関数ではサポートされていない

### ソーステーブルDeclaration
- 各ソーステーブル（`aiready`データセットのもの）は `dataform/definitions/sources/` に個別の `.sqlx` ファイルが必要
- 1つのファイルに複数の `config {}` ブロックを入れないこと — Dataformはこれをサポートしていない
- 各declarationファイルのフォーマット：
  ```
  config {
    type: "declaration",
    schema: "aiready",
    name: "テーブル名"
  }
  ```

---

## テストルール

### 共通ルール（全レイヤー）
- configブロックには必ず `type: "test"` と `dataset: "[テーブル名]"` の両方を含めること
- inputブロックの構文は厳密に `input "テーブル名" { SELECT col1, col2 FROM ... UNION ALL SELECT ... }` とすること — `input { name: "...", data: [...] }` のオブジェクト/配列形式は絶対に使用しないこと（Dataformに存在せず、コンパイルエラーになる）
- モックデータは最低5行用意すること
- テストファイルのどこにも `CURRENT_TIMESTAMP()` を含めないこと
- 期待出力は最後の `input {}` ブロックの後の単純な `SELECT` 文とすること — `expected { ... }` でラップしないこと（Dataformはこの構文をサポートしていない）
- UNION ALL の全行（`input` ブロックと期待出力の両方）は必ず `SELECT` で始めること。`SELECT col1 UNION ALL col2` のように後続行で `SELECT` を省略しないこと。正しい例：`SELECT col1 UNION ALL SELECT col2`。誤った例：`SELECT col1 UNION ALL col2`（構文エラーになる）
- 期待出力はハードコードされたリテラル値を使用すること — `SELECT ... FROM ${ref(...)}` や `SELECT ... FROM ${ self.name }` などのテーブル参照は絶対に使用しないこと
- 期待出力の値はモック入力データから決定論的に計算可能であること
- 文字列リテラルには常にシングルクォートを使用すること
- 浮動小数点の精度：期待値がFLOAT64入力の演算結果（AVG、除算など）の場合、小数リテラルではなく同じ演算式を期待出力に使用すること。例：`0.21` ではなく `(0.2 + 0.22) / 2` を使用すること（IEEE 754の不一致を防ぐため）

### Rawレイヤー（`raw_` プレフィックス）
共通ルールに加えて：
- Raw テーブルSQLでは `TIMESTAMP(CURRENT_DATE()) AS etl_loaded_at` と `CURRENT_DATE() AS etl_loaded_date` を使用すること — これらのカラムに `CURRENT_TIMESTAMP()` は絶対に使用しないこと
- テスト期待出力では、全行に `TIMESTAMP(CURRENT_DATE()) AS etl_loaded_at` と `CURRENT_DATE() AS etl_loaded_date` を含めること — これはテーブルSQLと一致し、1日以内は安定している
- `input {}` ブロックには `etl_loaded_at` と `etl_loaded_date` を含めないこと（これらはinputから取得するのではなく、rawテーブルSQLで追加される）
- 期待出力の他の全カラムはinputの行と完全に一致すること（同じ値）

### Processedレイヤー（`tmp_` プレフィックス）
共通ルールに加えて：
- モック入力値を使ってSQLロジックをステップごとにトレースし、期待出力を必ず計算すること — 期待出力を空のままにしないこと
- スケルトンを生成したり、期待出力をプレースホルダーにしたりしないこと
- `-- SKELETON: fill in expected output manually` や `-- TODO: verify this expected output manually` は絶対に使用しないこと
- 複雑なロジック（LAG、LEAD、ウィンドウ関数、単位変換、SCD2、複数ステップのWITH句）の場合：
  - 手計算できるほどシンプルなモックデータを設計すること（例：小さな明確な値、明確な日付シーケンス）
  - モックデータから各出力カラムの値を明示的に計算すること
- BigQuery LAG/LEAD の制約：3番目の引数（デフォルト値）は定数でなければならず、カラムは不可。`LAG(col, 1, col) OVER (...)` の代わりに `COALESCE(LAG(col, 1) OVER (PARTITION BY ... ORDER BY ...), col)` パターンを使用すること
- メインSQLで `SELECT * EXCEPT(col1, col2, ...)` を使用しないこと — 全出力カラムを明示的にリストすること。`* EXCEPT` パターンはテスト時にモック入力の唯一のカラムが除外対象の場合に失敗する（0カラム出力になる）
- テスト期待出力の行の順序：DataformはPositionalに行を比較する。`PARTITION BY` を含むクエリでは、BigQueryは1つのパーティションの全行を次のパーティションより先に返す（例：ウィンドウORDER BYでソートされたequip1の全行、その後equip2の全行）。期待出力はパーティション内順序のパターンに一致させること（パーティション横断の全体的なタイムスタンプ順ではない）
- SQLにバグや曖昧な動作がある場合は、前提条件を文書化するコメントを追加し、SQLが実際に生成する出力に一致する期待出力を生成すること
- 期待ブロックの上に以下のコメントを追加すること：
  `-- NOTE: expected output derived from mock data — verify if transformation logic changes`

### Accessレイヤー（`fct_`、`dim_` プレフィックス）
共通ルールに加えて：
- `${ref()}` で参照される各テーブルに個別の `input` ブロックを用意すること
- 全JOINが入力ごとに正確に1行一致するようにモックデータを設計すること — ファンアウトなし、JOINミスによるNULLなし
- 全inputテーブルは互いに一致するJOINキーを持つこと
- BETWEEN条件（非等価結合）の場合：モックデータのタイムスタンプが期待される範囲内に明示的に収まるように設計し、範囲を文書化するコメントを追加すること：
  `-- NOTE: [タイムスタンプカラム] は [開始カラム] と [終了カラム] の間に収まるように設計`
- テストファイルの先頭に以下のコメントを追加すること：
  `-- NOTE: mock data designed for deterministic JOIN results`

---

## 出力ルール
- ファイルは直接ディスクに書き込むこと — ファイルの内容をターミナルに表示しないこと
- 出力をmarkdownコードブロックやバッククォートでラップしないこと
- ファイルを書き込む前に確認を求めないこと
- 全手順完了後、レイヤー別にグループ化した作成ファイルのサマリーを表示すること

---

## 制約事項
- Project Contextで定義されていないデータセット名を推測または作成しないこと
- 生成ファイルに説明や前置きを含めないこと
- 要求されたテーブル名が `docs/requirements.md` に見つからない場合は、処理を止めて開発者に伝えること
- 変換ロジックが曖昧な場合は、生成ファイルの先頭にコメントとして前提条件を列挙すること
- 複雑さに関わらず、要求された全テーブルを必ず生成すること — テーブルをスキップしたり先延ばしにしたりしないこと。ロジックが複雑な場合は、ファイルを空にしたりスケルトンにしたりせず、基本的/簡略版を実装すること
