## Azure Database for PostgreSQL Flexible Server における セマンティックランキング

情報検索パイプラインの精度は、高度な Retrieval Augmented Generation (RAG) アプリケーションの品質において重要な役割を果たします。
Semantic Ranker Solution Accelerator を使用すると、Azure Database for PostgreSQL に セマンティックランカーモデル を拡張し、PostgreSQL の SQL クエリ内で直接利用することで、ベクター検索結果の精度を向上させることができます。
このソリューションアクセラレーターには、以下の機能が含まれています：
* 自動デプロイメントスクリプト により、セマンティックランカーモデルを Azure Machine Learning Inference Endpoint としてプロビジョニング
* PostgreSQL の SQL UDF（ユーザー定義関数） により、SQL クエリ内でランカーモデルを統合

このソリューションアクセラレーターを使用するには、[azure_ai](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/generative-ai-azure-overview) 拡張機能が必要です。

## セマンティックランカーソリューションのデモについて

私たちのソリューションアクセラレーターのデモでは、CNN-DailyMail データセットのサブセットを活用しています。このデータセットには、ジャーナリストによって執筆されたニュース記事が含まれています。
デモのプロセスは以下のように構成されています:

   1. 埋め込みとインデックス作成: まず、記事を埋め込み（Embedding）し、生成されたベクトルを Hierarchical Navigable Small World (HNSW) アルゴリズム を使用してインデックス化します。このステップにより、効率的かつスケーラブルなベクター検索機能が確保されます。
   2. クエリ処理: クエリを受信すると、そのクエリを埋め込み（Embedding）し、ベクター検索を通じて N 個の最も近いベクトル を取得します。これにより、最も関連性の高い記事を迅速に特定できます。
   3. セマンティックリランキング: 取得したベクトルを セマンティックランカーモデル に渡します。このモデルは、ベクトルの意味的関連性に基づいて順序を再評価し、上位 K 件の結果を返します。これにより、最も関連性の高い記事が優先的に表示されるようになります。

## 始める前に

* Azure サブスクリプションが必要です。
* [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd?tabs=winget-windows%2Cbrew-mac%2Cscript-linux&pivots=os-linux)のインストール
* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) のインストール
* `az extension add --name ml` による az ml 拡張機能のインストール
* デプロイするリージョンに十分な コンピュートクォータ が利用可能であることを確認してください。必要なクォータは Standard_NC24ads_A100_v4 の 24 CPU です ([Azure Machine Learning を使用するリソースのクォータと制限の管理と引き上げ](https://learn.microsoft.com/ja-jp/azure/machine-learning/how-to-manage-quotas?view=azureml-api-2))。

## デモ環境の作成

このデモでは、Bicep ファイル を使用して必要なリソースをデプロイします。以下の手順に従って、このデモを完了するために必要な Azure サービス を Azure サブスクリプション にデプロイしてください。

1. 以下のコマンドを入力して、演習リソースを含む GitHub リポジトリをクローンします:

    ```bash
    git clone https://github.com/microsoft/Semantic-Ranker-Solution-PostgreSQL.git
    cd Semantic-Ranker-Solution-PostgreSQL
    ```

2. Azure アカウントにログインします
    ```bash
    azd auth login
    ```

3. 新しい `azd` 環境を作成します

   ```bash
    azd env new
    ```

   リソースグループに使用する名前を入力してください。これにより、`.azure` フォルダー内に新しいフォルダーが作成され、以降の `azd` コマンドの呼び出しで アクティブな環境 として設定されます。

4. リソースのプロビジョニング

    ```bash
    azd up
    ```

    これにより、Azure Database for PostgreSQL Flexible Server、Azure OpenAI サービス、および Azure Machine Learning Workspace を含む Azure リソース がプロビジョニングされ、このサンプルがそれらのリソースにデプロイされます。

5. リランカーモデルのデプロイ

   ```bash
   bash deploy_model.sh
   ```

   これにより、Hugging Face から リランカーモデル をダウンロードし、Azure Machine Learning Workspace にデプロイします。

## Azure Database for PostgreSQL Flexible Server におけるセマンティックリランキング

6. データベースのホスト名、ユーザー名、およびデータベース名を指定して、データベースに接続します

    ```bash
    # azd 環境から環境変数を読み込む
    source <(azd env get-values)
    # PostgreSQL に接続
    psql --host=$AZURE_POSTGRES_HOST --port=5432 --username=$AZURE_POSTGRES_USERNAME --dbname=$AZURE_POSTGRES_DB_NAME
    ```

7. 必要な拡張機能を作成しセットアップする

    ```sql
    \i setup_azure_ai.sql
    ```

   OpenAI エンドポイント と サブスクリプションキー、および Azure Machine Learning のスコアリングエンドポイント と キー（デプロイ済みの埋め込みモデルおよびリランカーモデル用）を入力するよう求められます。
   >
   > You can find the endpoint and the keys for your Azure OpenAI resource under Resource Management
   > Keys and Endpoints in the the Azure OpenAI resource. Similarly, in the Azure Machine Learning studio, under Endpoints
   > Pick your endpoint
   > Consume you can find the endpoint URI and Key for the online endpoint.

9. デモの実行

    ```sql
    \i semantic_reranker_demo.sql
    ```

    ベクター検索とリランキングの後、「人工知能に関する最新ニュース」 というクエリに対して、上位 3 件の記事 とその 関連性スコア を返します。
