zabbix-jmxsetting
=================
ZABBIXのホストに対して、JMXインターフェースの設定とJMXを利用するテンプレートの設定を行います。

前提
-----
ZABBIX 2.0にて動作を確認しています。

`jq`がZABBIX SERVERにインストールされている必要があります。  
[jq](http://stedolan.github.io/jq/)

使い方
-----
Zabbixの管理画面から、[設定]→[アクション]→イベントソース[自動登録]を選択し、好きなアクションに対して[アクションの実行内容]から本スクリプトを指定してください。

[実行内容の詳細]は以下の通りです。

* 実行内容のタイプ  : リモートコマンド
* ターゲットリスト : 現在のホスト
* タイプ : カスタムスクリプト
* 次で実行 : Zabbixサーバー
* コマンド : `(path)/zabbix-jmxsetting.sh {HOST.HOST} {HOST.IP}`

注意事項
-----
事前に、スクリプト内でそれぞれの環境用に以下を書き換えてください。

* TEMPLATE_JMX : JMXテンプレート名
* ADMINUSER : ZABBIX WEB管理者ユーザ名
* ADMINPASSWORD : ZABBIX WEB管理者パスワード
