# 通过 Bucket Level Policy 加强 AWS S3 数据安全防护


通过 Bucket Level Policy 合理限制 S3 Bucket 访问请求来源后，能够在 AKSK 泄露的情况下仍然保障 AWS S3 Bucket 的数据安全。

<!--more-->

---

## 背景

随着公有云的不断发展，越来越多的企业通过云服务来构建基础设施，并采用对象存储作为企业的数据底座。

由于安全意识较弱，大量的技术人员为了方便，喜欢通过 AKSK（Access Key and Secret Key）的授权方式对资源进行访问。AKSK 由两串字符构成，通过 AKSK 能够直接用命令行工具或 API 代码获取到对应用户的权限。以 AWS 为例，通过一个简单的`aws s3 sync`命令就可以将 S3 Bucket 的数据全部拖走。

由于 AKSK 泄露造成对象存储中数据被拖走的案例，可谓是屡见不鲜，部分案例所造成的影响甚至可以用骇人听闻来形容。采用技术手段规避掉这类风险是很有必要的，以 AWS 为例，通过 Bucket Level Policy 合理限制 S3 Bucket 的访问请求来源后，能够在 AKSK 泄露的情况下仍然保障 AWS S3 Bucket 的数据安全。

当然，这里还有一个前提，就是泄露的 AKSK 对应用户的权限不能太大，比如具备管理员权限或包含其它服务如 IAM、EC2、Lambda 等服务的完整权限。否则仍然可能通过其它服务绕过 Bucket Level Policy 的合理限制或修改重置 Bucket Level Policy，造成权限蔓延。对于这类情况，可以通过 SCP 从组织账号级别对各种服务进行限制，Policy 也会更复杂一些。

## Policy 示例

以下 Bucket Level Policy 示例代码默认采用了 Deny（禁用）策略，仅对以下几种请求放行：

1. 当请求直接来自于 AWS Service；
2. 当请求来自于指定的 VPC ID；
3. 当请求来自于指定的 Role；
4. 当请求来自于指定的 IP。

```json
{
    "Version": "2012-10-17",
    "Id": "RestrictVPCsAndARNsAndSourceIPs",
    "Statement": [
        {
            "Sid": "VPCsAndARNsAndSourceIPs",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::bucket-name",
                "arn:aws:s3:::bucket-name/*"
            ],
            "Condition": {
                "Bool": {
                    "aws:ViaAWSService": "false"
                },            
                "StringNotEqualsIfExists": {
                    "aws:SourceVpc": [
                        "vpc-857abc857abc875aa",
                        "vpc-857cba857cba875bb"
                    ]
                },
                "ArnNotLikeIfExists": {
                    "aws:PrincipalArn": [
                        "arn:aws:iam::857857857857:role/role-name",
                        "arn:aws:iam::361361361361:role/role-name",
                        "arn:aws:iam::857857857857:role/role*",
                        "arn:aws:iam::361361361361:role/role*"
                    ]
                },
                "NotIpAddressIfExists": {
                    "aws:SourceIp": [
                        "8.5.7.11/32",
                        "8.5.7.22/32"
                    ]
                }
            }
        }
    ]
}
```

## 更完善的方案

更加完善地保障 S3 Bucket 的数据安全，可以通过访问来源、最小访问权限、安全监测、日志监控、数据加密、配置检查、数据副本等方面开展：

1. 通过 SCP 从组织账号级别限制 S3 以及其它 AWS Service 的访问来源
2. 通过 Bucket Level Policy 限制具体的 S3 Action
3. 启用 GuardDuty 监测可疑的 S3 访问活动
4. 使用 Macie 扫描 S3 中的敏感数据
5. 启用 KMS 加密 S3 中的数据
6. 启用 S3 Versioning 保留数据副本避免误删除，或启用 S3 Object Lock 禁用数据删除功能
7. 启用 S3 访问日志和 CloudTrail 日志监控
8. 通过 Security Hub 检查 S3 设置，对 CloudWatch 日志进行自定义分析和报警
9. 采用 S3 跨区域复制功能自动同步备份

## 参考

https://docs.aws.amazon.com/AmazonS3/latest/userguide/example-bucket-policies.html  
https://aws.amazon.com/cn/blogs/security/top-10-security-best-practices-for-securing-data-in-amazon-s3/

