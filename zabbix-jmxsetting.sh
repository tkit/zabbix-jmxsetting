#! /bin/bash

# 対象のZabbixホスト名
ADDHOSTNAME="$1"
# 対象のZabbixホストのIP
ADDIP="$2"
# JMXを利用するテンプレート名
TEMPLATE_JMX="Template JMX Tomcat 7"

# トークン取得用のユーザ名/パスワード
ADMINUSER="Admin"
ADMINPASSWORD="zbxqas!"

JMX_IF_IP="${ADDIP}"
JMX_IF_DNS=""

CONTENT_TYPE="Content-Type: application/json-rpc"
URL="http://localhost/zabbix/api_jsonrpc.php"

# アクセス用のトークンを取得
# 以降、このトークンを利用してzabbixを操作する
getZabbixToken() {
  export ZABBIX_TOKEN=`curl -s -d '
  {
      "auth":null,
      "method":"user.authenticate",
      "id":1,
      "params":{
          "password":"'${ADMINPASSWORD}'",
          "user":"'${ADMINUSER}'"
       },
      "jsonrpc":"2.0"
  }' -H "${CONTENT_TYPE}" "${URL}" | jq ".result"` 
}

if [ "${ZABBIX_TOKEN}" == "" ] ; then
  getZabbixToken
fi

# 設定対象のホストIDを取得する
HOSTID=`curl -s -d '
{
    "auth":'${ZABBIX_TOKEN}',
    "method":"host.get",
    "id":1,
    "jsonrpc":"2.0",
    "params":{
        "output":"hostid",
        "filter":{
            "name" : "'${ADDHOSTNAME}'"
        }
    }
}'  -H "${CONTENT_TYPE}" "${URL}" | jq ".result[].hostid"`

# Template app Tomcat 7 のTemplateidを取得する

TEMPLATEID=`curl -s -d '
{
    "auth": '${ZABBIX_TOKEN}',
    "method": "template.get",
    "id": 1,
    "jsonrpc": "2.0",
    "params":{
        "output":"templateid",
        "filter":{
            "name" : "'"${TEMPLATE_JMX}"'"
        }
    }
}' -H "${CONTENT_TYPE}" "${URL}" | jq ".result[].templateid"`

# 対象ホストのjmxインターフェースの存在有無を確認する
# type=4がjmxインターフェース
# 存在しなければ空、すればinterfaceidが返ってくる
JMX_IF_EXIST=`curl -s -d '
{
    "auth":'${ZABBIX_TOKEN}',
    "method":"hostinterface.get",
    "id":1,
    "jsonrpc":"2.0",
    "params":{
        "output":"extend",
        "hostids":'${HOSTID}',
        "filter":{
            "type" : "4"
        }
    }
}' -H "${CONTENT_TYPE}" "${URL}" | jq ".result[]"`

# 上記で存在しなければ、jmxインターフェースを作成する
if [ "${JMX_IF_EXIST}" == "" ] ; then
    curl -s -d '
    {
        "auth": '${ZABBIX_TOKEN}',
        "method": "hostinterface.create",
        "id": 1,
        "jsonrpc": "2.0",
        "params": {
            "hostid": '${HOSTID}' ,
            "ip": "'${JMX_IF_IP}'",
            "dns": "'${JMX_IF_DNS}'" ,
            "main": "1",
            "port": "10080",
            "type": "4",
            "useip": "1"
        }
    }' -H "${CONTENT_TYPE}" "${URL}" | jq "."
fi

# templateidが対象ホストにlinkされているかを確認する
TEMPLATE_EXIST=`curl -s -d '
{
    "auth":'${ZABBIX_TOKEN}',
    "method":"host.get",
    "id":1,
    "jsonrpc":"2.0",
    "params":{
        "output":"hostid",
        "hostids" : '${HOSTID}',
        "templateids" : '${TEMPLATEID}'
    }
}'  -H "${CONTENT_TYPE}" "${URL}" | jq ".result[]"`

# linkされていなければ、テンプレートをlinkする
if [ "${TEMPLATE_EXIST}" == "" ] ; then
    curl -s -d '
    {
        "auth": '${ZABBIX_TOKEN}',
        "method": "template.massadd",
        "id": 1,
        "jsonrpc": "2.0",
        "params": {
            "templates":[
                {
                    "templateid":'${TEMPLATEID}'
                }
            ],
            "hosts":[
                {
                    "hostid":'${HOSTID}'
                }
            ]
        }
    }' -H "${CONTENT_TYPE}" "${URL}" | jq "."
fi

