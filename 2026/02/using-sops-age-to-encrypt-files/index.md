# 使用 SOPS + age 加解密文件


[SOPS](https://github.com/getsops/sops) 的全称是 Secrets OPerationS，官方简介为 Simple and flexible tool for managing secrets，定位是简单灵活的密钥管理工具。  
与 [age](https://github.com/FiloSottile/age) 加解密工具配合后，相比 git-crypt，管理私钥更方便、操作更直观、更容易与 CI 集成。

<!--more-->

---

## 安装工具

安装 SOPS 和 age

```plain
❯ brew install sops age
```

## 创建目录和文件

创建所需的目录以模拟多用户协作

```plain
❯ mkdir -p /Users/damonguo/Workspace/demo/sops-age/{age_keys,repo}
❯ cd /Users/damonguo/Workspace/demo/sops-age/
❯ ls -1
age_keys
repo
```

以用户 Alice 的身份新建 config.yaml

```plain
❯ cd repo
❯ cat > config.yaml <<EOF
database:
  host: localhost
  username: app
  password: abcd_1234

api:
  timeout: 30
  access_token: dummy12345

service:
  - name: foo
    client_secret: abcdef123456
  - name: bar
    client_secret: uvwxyz456789
EOF
```

## 生成 age keys

为用户 Alice，Bob 和 Jack 生成 age keys

```plain
❯ touch /Users/damonguo/Workspace/demo/sops-age/age_keys/{alice,bob,jack}.key
❯ chmod 600 /Users/damonguo/Workspace/demo/sops-age/age_keys/*.key

❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops-age/age_keys/alice.key
❯ age-keygen > $SOPS_AGE_KEY_FILE
Public key: age1lz4xs2z4rwcd9t4g3ek7vlj49x7uqzjnug3l8996tac40y4saatsw0ezx9

❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops-age/age_keys/bob.key
❯ age-keygen > $SOPS_AGE_KEY_FILE
Public key: age1ckhckhz2jpzu574u83vcx88twfu2zqx9t42lf9623ysqx3h23c7s2gwj7m

❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops-age/age_keys/jack.key
❯ age-keygen > $SOPS_AGE_KEY_FILE
Public key: age1h0ufdryerkpy39xkun9zd2hrece3g7nu9l63ws927cngwk633dcspuvgal

❯ cat /Users/damonguo/Workspace/demo/sops-age/age_keys/alice.key
# created: 2026-02-03T17:41:06+08:00
# public key: age1lz4xs2z4rwcd9t4g3ek7vlj49x7uqzjnug3l8996tac40y4saatsw0ezx9
AGE-SECRET-KEY-1ZU2XLLK73TEAY4Z4JQFDJH4VUA796QTN3GJ246YJKV2C5N7Z7TUSM24TWZ
```

## 授权并校验

创建 .sops.yaml 文件，定义加密规则

```yaml
❯ vim .sops.yaml
stores:
  # YAML 文件默认采用 2 空格缩进
  yaml:
    indent: 2

creation_rules:
    # 匹配 config.yaml 文件
  - path_regex: 'config\.yaml$'
    # key 名包含 password/secret/token (不区分大小写) 就加密
    encrypted_regex: '(?i)(password|secret|token)'
    # 解密者公钥
    age:
      - age1lz4xs2z4rwcd9t4g3ek7vlj49x7uqzjnug3l8996tac40y4saatsw0ezx9
```

以用户 Alice 的身份加密 config.yaml

```plain
❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops-age/age_keys/alice.key

❯ sops --encrypt --in-place config.yaml

❯ cat config.yaml
database:
  host: localhost
  username: app
  password: ENC[AES256_GCM,data:KSNypavbjvcY,iv:QG7DLWflC9ledyPegIN2pFRhC9Qv/C0aEPOBilOg710=,tag:qYBqXAYnskV9i6Dk0VqvOA==,type:str]
api:
  timeout: 30
  access_token: ENC[AES256_GCM,data:3rYCpMxrBwpIcQ==,iv:vgwFe+Xha6BUiMsQpFhqG/g82kWkvtUY2Q88YPRR3qY=,tag:9U1C1WK14vamwBcCgDi6KA==,type:str]
service:
  - name: foo
    client_secret: ENC[AES256_GCM,data:W7pCfqvdKpIj72Ww,iv:zEjNCwkO38uiSEyuS3kIbYewFNg4ey7EbN1x/feowz4=,tag:WI5Uh5CdxhQVaECmTjNV8g==,type:str]
  - name: bar
    client_secret: ENC[AES256_GCM,data:gpZhOBKH2OnPAh1c,iv:MZWYUCBHNZ+oM7ev6gEcIC860OsWh+GKVrKiyhILTrw=,tag:PyP50EsJXRPMwPRUnPuDbA==,type:str]
sops:
  age:
    - recipient: age1lz4xs2z4rwcd9t4g3ek7vlj49x7uqzjnug3l8996tac40y4saatsw0ezx9
      enc: |
        -----BEGIN AGE ENCRYPTED FILE-----
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSA1dk1HM0JVeGVBNkhPUmxy
        VFZYUTNIN3ViTktXaDB2emNidWxLenVqYjBVCmtVTnFwcjhCNUFUZk85d2lUbzhM
        WmFSYU1HSmhPUG4rUHdpa1RqeG5hYjAKLS0tIE9RRHFWa0JnMXZZV0dTU1JPM1VL
        TWUwWVpzVEd6b1FQOEdtOERwZGlFdmcK3qRblOKDUEyokw8DmOZ/rQILrKcU3ESM
        9Uddh0KLn/N37KCdEJc+NVXa+lCR9WbbNnNVPCh4ZcyxKGzY1f3Uvw==
        -----END AGE ENCRYPTED FILE-----
  lastmodified: "2026-02-03T09:59:28Z"
  mac: ENC[AES256_GCM,data:qmw//bM0Kxo7KtTa1Ac955qzNnzsGpqd9/yhmQcq2q+mIvDj4YBPGkBg2hAhp7y3JYPGOdgCPgzJV41MvZe4Mwab1mdPU+EWTY+fDpaMll67rB28oO1XT3/W3MLSruWMTCMyeGApwFRRSP8KNzIXLMje/cz1rAbt4pPCsD8X6eM=,iv:VunSwYXgB70WpnbYB22bls8INj5bZ8VrNPMSA1XsLQ8=,tag:jOUQsg9YZZ52ylbvNp6PCw==,type:str]
  encrypted_regex: (?i)(password|secret|token)
  version: 3.11.0
```

解密验证

```plain
❯ sops --decrypt config.yaml
database:
  host: localhost
  username: app
  password: abcd_1234
api:
  timeout: 30
  access_token: dummy12345
service:
  - name: foo
    client_secret: abcdef123456
  - name: bar
    client_secret: uvwxyz456789
```

以用户 Bob 的身份尝试未授权状态下解密

```plain
❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops-age/age_keys/bob.key

❯ sops --decrypt config.yaml
Failed to get the data key required to decrypt the SOPS file.

Group 0: FAILED
  age1lz4xs2z4rwcd9t4g3ek7vlj49x7uqzjnug3l8996tac40y4saatsw0ezx9: FAILED
    - | failed to create reader for decrypting sops data key with
      | age: no identity matched any of the recipients. Did not find
      | keys in locations 'SOPS_AGE_SSH_PRIVATE_KEY_FILE',
      | '/Users/damonguo/.ssh/id_ed25519', 'SOPS_AGE_KEY', and
      | 'SOPS_AGE_KEY_CMD'.

Recovery failed because no master key was able to decrypt the file. In
order for SOPS to recover the file, at least one key has to be successful,
but none were.
```

以用户 Alice 的身份授权给 Bob

```plain
❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops-age/age_keys/alice.key

❯ vim .sops.yaml
stores:
  # YAML 文件默认采用 2 空格缩进
  yaml:
    indent: 2

creation_rules:
    # 匹配 config.yaml 文件
  - path_regex: 'config\.yaml$'
    # key 名包含 password/secret/token (不区分大小写) 就加密
    encrypted_regex: '(?i)(password|secret|token)'
    # 解密者公钥
    age:
      - age1lz4xs2z4rwcd9t4g3ek7vlj49x7uqzjnug3l8996tac40y4saatsw0ezx9
      - age1ckhckhz2jpzu574u83vcx88twfu2zqx9t42lf9623ysqx3h23c7s2gwj7m

❯ sops updatekeys config.yaml
2026/02/03 18:00:11 Syncing keys for file /Users/damonguo/Workspace/demo/sops-age/repo/config.yaml
The following changes will be made to the file's groups:
Group 1
    age1lz4xs2z4rwcd9t4g3ek7vlj49x7uqzjnug3l8996tac40y4saatsw0ezx9
+++ age1ckhckhz2jpzu574u83vcx88twfu2zqx9t42lf9623ysqx3h23c7s2gwj7m
Is this okay? (y/n):y
2026/02/03 18:00:13 File /Users/damonguo/Workspace/demo/sops-age/repo/config.yaml synced with new keys
```

以用户 Bob 的身份尝试已授权状态下解密

```plain
❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops-age/age_keys/bob.key

❯ sops --decrypt config.yaml
database:
  host: localhost
  username: app
  password: abcd_1234
api:
  timeout: 30
  access_token: dummy12345
service:
  - name: foo
    client_secret: abcdef123456
  - name: bar
    client_secret: uvwxyz456789
```

## 移除授权并校验

已授权的用户 Bob 可以将 Alice 的密钥移除，并添加 Jack 的授权

```plain
❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops-age/age_keys/bob.key

❯ vim .sops.yaml
stores:
  # YAML 文件默认采用 2 空格缩进
  yaml:
    indent: 2

creation_rules:
    # 匹配 config.yaml 文件
  - path_regex: 'config\.yaml$'
    # key 名包含 password/secret/token (不区分大小写) 就加密
    encrypted_regex: '(?i)(password|secret|token)'
    # 解密者公钥
    age:
      - age1ckhckhz2jpzu574u83vcx88twfu2zqx9t42lf9623ysqx3h23c7s2gwj7m
      - age1h0ufdryerkpy39xkun9zd2hrece3g7nu9l63ws927cngwk633dcspuvgal

❯ sops updatekeys config.yaml
2026/02/03 18:01:56 Syncing keys for file /Users/damonguo/Workspace/demo/sops-age/repo/config.yaml
The following changes will be made to the file's groups:
Group 1
    age1ckhckhz2jpzu574u83vcx88twfu2zqx9t42lf9623ysqx3h23c7s2gwj7m
+++ age1h0ufdryerkpy39xkun9zd2hrece3g7nu9l63ws927cngwk633dcspuvgal
--- age1lz4xs2z4rwcd9t4g3ek7vlj49x7uqzjnug3l8996tac40y4saatsw0ezx9
Is this okay? (y/n):y
2026/02/03 18:01:58 File /Users/damonguo/Workspace/demo/sops-age/repo/config.yaml synced with new keys
```

用户 Alice 无法再解密 config.yaml

```plain
❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops-age/age_keys/alice.key

❯ sops --decrypt config.yaml
Failed to get the data key required to decrypt the SOPS file.

Group 0: FAILED
  age1ckhckhz2jpzu574u83vcx88twfu2zqx9t42lf9623ysqx3h23c7s2gwj7m: FAILED
    - | failed to create reader for decrypting sops data key with
      | age: no identity matched any of the recipients. Did not find
      | keys in locations 'SOPS_AGE_SSH_PRIVATE_KEY_FILE',
      | '/Users/damonguo/.ssh/id_ed25519', 'SOPS_AGE_KEY', and
      | 'SOPS_AGE_KEY_CMD'.

  age1h0ufdryerkpy39xkun9zd2hrece3g7nu9l63ws927cngwk633dcspuvgal: FAILED
    - | failed to create reader for decrypting sops data key with
      | age: no identity matched any of the recipients. Did not find
      | keys in locations 'SOPS_AGE_SSH_PRIVATE_KEY_FILE',
      | '/Users/damonguo/.ssh/id_ed25519', 'SOPS_AGE_KEY', and
      | 'SOPS_AGE_KEY_CMD'.

Recovery failed because no master key was able to decrypt the file. In
order for SOPS to recover the file, at least one key has to be successful,
but none were.
```

用户 Bob 和 Jack 可以解密 config.yaml

```plain
❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops-age/age_keys/jack.key
❯ sops --decrypt config.yaml
database:
  host: localhost
  username: app
  password: abcd_1234
api:
  timeout: 30
  access_token: dummy12345
service:
  - name: foo
    client_secret: abcdef123456
  - name: bar
    client_secret: uvwxyz456789

❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops-age/age_keys/jack.key
❯ sops --decrypt config.yaml
database:
  host: localhost
  username: app
  password: abcd_1234
api:
  timeout: 30
  access_token: dummy12345
service:
  - name: foo
    client_secret: abcdef123456
  - name: bar
    client_secret: uvwxyz456789
```

用户 Jack 可以用命令 `sops` 自动解密编辑 config.yaml，编辑完成后自动加密

```plain
❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops-age/age_keys/jack.key
❯ sops config.yaml
database:
  host: localhost
  username: app
  password: abcd_1234
api:
  timeout: 30
  access_token: dummy56789
service:
  - name: foo
    client_secret: abcdef123456
  - name: bar
    client_secret: uvwxyz456789

❯ sops --decrypt config.yaml
database:
  host: localhost
  username: app
  password: abcd_1234
api:
  timeout: 30
  access_token: dummy56789
service:
  - name: foo
    client_secret: abcdef123456
  - name: bar
    client_secret: uvwxyz456789
```

查看加密后的 config.yaml 文件内容

```plain
❯ cat config.yaml
database:
  host: localhost
  username: app
  password: ENC[AES256_GCM,data:y88DSJ5vXkyA,iv:sROb0UYccXYjEfDQD7fnF14Sr55Zj7djSnKQoARZjAA=,tag:Ykt6b8+YkvrGmoU9JpdRAw==,type:str]
api:
  timeout: 30
  access_token: ENC[AES256_GCM,data:Jgj2jkxhZAEhiQ==,iv:u/uf7VAK0MbySLS06X7dW3cX3K1S4B+VIzCtDgwOZ5o=,tag:q0otHUXfHyctxZiz2QRnQQ==,type:str]
service:
  - name: foo
    client_secret: ENC[AES256_GCM,data:0PCLP7VXe7u5Pmb6,iv:ExUPwsa8JYpoTQhVdXVApEALc4b1dmX0f+2mf1zJ30Q=,tag:eeLLULLpVLXz3PXPVmrjiw==,type:str]
  - name: bar
    client_secret: ENC[AES256_GCM,data:aSFxII+/Rc6ma+zw,iv:/nhi1giX9rx1wr/qvYeX1cBj6FoADZfwD1Xs4taBClQ=,tag:Fwk4aLNECrszQ97coK1FnA==,type:str]
sops:
  age:
    - recipient: age1ckhckhz2jpzu574u83vcx88twfu2zqx9t42lf9623ysqx3h23c7s2gwj7m
      enc: |
        -----BEGIN AGE ENCRYPTED FILE-----
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSByanlTVkJSU3FSTUFFaVRV
        NXRJSStwZHRVbGVQUjZ1NVU0RFIvUlhGQkdnCjh2VzlUN3NVK3Y1UHRIblYyWU5r
        czdZbkNkRERwc1I0WmVvajZ1MFZ3YncKLS0tIGt1MzMrdlRrSlpBNllvNUFYUzE5
        TTdQa3NOanM0OFFaeGcvNHBHbk1Ba3cKdroSdS8pChvjREYTP+O42VWV5+WcS+UU
        Sd7oxkBqYc/fHgG45pcHNdOvddPGSsKPr+mk1quO8dtofJWvXnyRVw==
        -----END AGE ENCRYPTED FILE-----
    - recipient: age1h0ufdryerkpy39xkun9zd2hrece3g7nu9l63ws927cngwk633dcspuvgal
      enc: |
        -----BEGIN AGE ENCRYPTED FILE-----
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBVTWQ2R2ZSQ01GaE5nRmRi
        S3V0aHU3aEhDcDlhOFJ3akFCbE1kSXc3UHlVCld4UEU1VXIxMm01RFhlVWVVMThO
        aXpZS01IWjlzLyswY2FSMFBlZDNNbUkKLS0tIExEdmpWdkxPWlpiQjlnMi9tMXUv
        VXorMy9XamtUM3JTSlFxQ045bjBBdkEKlHLnr8XMOJHxXACIl7MSfgcpE2HxCDRm
        Y3jTPxNlZXzy44q1q/tf2oHvp40VmLyQ4fB8tDj/0p/eyfVZWtCRjQ==
        -----END AGE ENCRYPTED FILE-----
  lastmodified: "2026-02-03T10:04:01Z"
  mac: ENC[AES256_GCM,data:Q7qv3BOUjtJ2PRE6+Ucdy1tNeKOGs3X0hNzzDruq/bInR50jo4aiY7u25XQmVLQBwQmDjIgeF83KMDx0g/f1n1AxCTP5gxQfyR2HI2rjMiy16WlvrYNyFZsXJto4ce07wJEoECiYO5VDjGPo0qa1N3RCg2w7yy4P7TKcWk//vos=,iv:L87g5UMWTmC7F+SXimxcbqVu8cVg5LMrXCpfNSfzKlE=,tag:iPgMNJ0KhZ4J+Pk0d51Kxg==,type:str]
  encrypted_regex: (?i)(password|secret|token)
  version: 3.11.0
```

## 参考

https://blog.gitguardian.com/a-comprehensive-guide-to-sops/

