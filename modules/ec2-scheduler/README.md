# EC2 Scheduler Module

このモジュールは、AWS EventBridge SchedulerとSSM Automationを使用してEC2インスタンスの自動開始・停止を行うTerraformモジュールです。

## 機能

- 指定したスケジュールでEC2インスタンスを自動開始
- 指定したスケジュールでEC2インスタンスを自動停止
- タグベースでの対象インスタンス管理
- 環境別での制御

## 動作原理

1. **タグベースフィルタリング**: `AutoStart=true`または`AutoStop=true`タグが付いたEC2インスタンスを対象とします
2. **Resource Groups**: 対象インスタンスをResource Groupsで管理
3. **EventBridge Scheduler**: 指定されたcron式に基づいてスケジュール実行
4. **SSM Automation**: AWS-StartEC2InstanceおよびAWS-StopEC2Instanceドキュメントを使用してインスタンスを制御

## 使用方法

```hcl
module "ec2_scheduler" {
  source = "./modules/ec2-scheduler"

  account_id                     = "123456789012"
  region                        = "ap-northeast-1"
  environment                   = "dev"
  resource_name_prefix          = "my-project"
  start_schedule_expression     = "cron(0 10 ? * MON-FRI *)"
  stop_schedule_expression      = "cron(0 19 ? * MON-FRI *)"
  schedule_expression_timezone  = "Asia/Tokyo"
}
```

## 必要なタグ

対象のEC2インスタンスには以下のタグを設定してください：

- **AutoStart**: `true` - 自動開始対象のインスタンス
- **AutoStop**: `true` - 自動停止対象のインスタンス
- **Environment**: 環境名（例：`dev`, `stg`, `prod`）

## 作成されるリソース

- IAMロール（SSM Automation用、EventBridge Scheduler用）
- IAMポリシー
- Resource Groups（開始用、停止用）
- EventBridge Scheduler（開始用、停止用）

## 変数

| 変数名 | 説明 | 型 | 必須 |
|--------|------|-----|------|
| `account_id` | AWSアカウントID | string | ✓ |
| `region` | AWSリージョン | string | ✓ |
| `environment` | 環境名 | string | ✓ |
| `resource_name_prefix` | リソース名のプレフィックス | string | ✓ |
| `start_schedule_expression` | 開始スケジュールのcron式 | string | ✓ |
| `stop_schedule_expression` | 停止スケジュールのcron式 | string | ✓ |
| `schedule_expression_timezone` | スケジュールのタイムゾーン | string | ✓ |

## 注意事項

- EventBridge Schedulerのcron式はUTC基準で設定されるため、タイムゾーンの指定が重要です
- 対象インスタンスには適切なタグが設定されている必要があります
- SSM Automationの実行権限が必要です
