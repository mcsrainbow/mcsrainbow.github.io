# 使用 SOPS + AGE 加解密文件


SOPS 的全称是 Secrets OPerationS，官方简介为 Simple and flexible tool for managing secrets，定位是简单灵活的密钥管理工具。  
与 AGE (Actual Good Encryption) 加解密工具配合后，相比 git-crypt，管理私钥更方便、操作更直观、更容易与 CI 集成。

<!--more-->

---

## 安装工具

安装 SOPS 和 AGE

```plain
❯ brew install sops age
```

## 创建目录和文件

创建所需的目录以模拟多用户协作

```plain
❯ mkdir -p /Users/damonguo/Workspace/demo/{repo,sops_keys}
❯ cd /Users/damonguo/Workspace/demo/
❯ ls -1
repo
sops_keys
```

以用户 Alice 的身份新建 secrets.yml

```plain
❯ cd repo
❯ mkdir sops-demo

❯ cd sops-demo
❯ cat > secrets.yml <<EOF
db:
  username: super-secret
  password: ultra-secret
EOF
❯ cat secrets.yml
db:
  username: super-secret
  password: ultra-secret
```

## 生成 AGE Keys

为用户 Alice，Bob 和 Jack 生成 AGE Keys

```plain
❯ touch /Users/damonguo/Workspace/demo/sops_keys/{alice,bob,jack}.key
❯ chmod 600 /Users/damonguo/Workspace/demo/sops_keys/*.key

❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops_keys/alice.key
❯ age-keygen > $SOPS_AGE_KEY_FILE
Public key: age1lz4xs2z4rwcd9t4g3ek7vlj49x7uqzjnug3l8996tac40y4saatsw0ezx9

❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops_keys/bob.key
❯ age-keygen > $SOPS_AGE_KEY_FILE
Public key: age1ckhckhz2jpzu574u83vcx88twfu2zqx9t42lf9623ysqx3h23c7s2gwj7m

❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops_keys/jack.key
❯ age-keygen > $SOPS_AGE_KEY_FILE
Public key: age1h0ufdryerkpy39xkun9zd2hrece3g7nu9l63ws927cngwk633dcspuvgal

❯ cat /Users/damonguo/Workspace/demo/sops_keys/alice.key
# created: 2026-02-03T17:41:06+08:00
# public key: age1lz4xs2z4rwcd9t4g3ek7vlj49x7uqzjnug3l8996tac40y4saatsw0ezx9
AGE-SECRET-KEY-1ZU2XLLK73TEAY4Z4JQFDJH4VUA796QTN3GJ246YJKV2C5N7Z7TUSM24TWZ
```

## 授权并校验

以用户 Alice 的身份加密 secrets.yml，并解密验证

```plain
❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops_keys/alice.key

❯ sops --encrypt --in-place --age age1lz4xs2z4rwcd9t4g3ek7vlj49x7uqzjnug3l8996tac40y4saatsw0ezx9 secrets.yml
❯ cat secrets.yml
db:
    username: ENC[AES256_GCM,data:K4o7b88VYy1fiIRK,iv:WMPXoFF0aaxktEjaFxliYpsDgb77MVvbwviuwmYCRsk=,tag:qM3PzdjkyqYL2U+Ryhw/+Q==,type:str]
    password: ENC[AES256_GCM,data:SBIn28H5hlTNb0Xg,iv:BouoeNldrph5vph1ti2Y5Xny/qI5dQaFHCbsAFy/Ezo=,tag:X6SYXPgDU0R+WIVO0da+cA==,type:str]
sops:
    age:
        - recipient: age1lz4xs2z4rwcd9t4g3ek7vlj49x7uqzjnug3l8996tac40y4saatsw0ezx9
          enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBkSkNRLzYrUjFNRTNQdHAr
            YitPZXNPZk8xdXZ3ZWNsRkdqaE1RSUpkVXc0Cll1TDJ5SFI2ckdIR0FNay9HWjFm
            QmJXSk8rdm9vQXltL3ZBbVVldGxZVU0KLS0tIFJRRlBsZmVtRW4yVStxUVFobjRo
            bmxUS2xPWlMydlFlTm1IZWp5OWdERncKkU/H0ovZpSCjrBRlitwp0iXiKB2VesL7
            BeYvdfvC0DeNZOyUYeAageEnYdm4z5Su7EmievmiYADVB20v/37Qog==
            -----END AGE ENCRYPTED FILE-----
    lastmodified: "2026-02-03T10:00:15Z"
    mac: ENC[AES256_GCM,data:5rbslKqxuIVbsilV3BFvlKw6BV2mUjGV0dmizTAXJgW5iC6n3I4ByGanc40lU/OjE02upvNo11NuoUtbDv7h1K+/XxFU7DlwMEJ7BGVdWU9Dq5fhf4eF2tcV5Q+Dw4JawUiMbBE25T3J0m+CMRx/Fb9KSRryYF7jb07l+QlTSrI=,iv:PasAhpZQI8h95vBu4szxxTyENYDgUimsYykS540svF8=,tag:/uHDwWrvqY6OYVjullgwhA==,type:str]
    unencrypted_suffix: _unencrypted
    version: 3.11.0

❯ sops --decrypt secrets.yml
db:
  username: super-secret
  password: ultra-secret
```

以用户 Bob 的身份尝试未授权状态下解密

```plain
❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops_keys/bob.key

❯ sops --decrypt secrets.yml
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
❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops_keys/alice.key

❯ vim .sops.yaml
creation_rules:
  - path_regex: ^secrets\.yml$
    age:
      - age1lz4xs2z4rwcd9t4g3ek7vlj49x7uqzjnug3l8996tac40y4saatsw0ezx9
      - age1ckhckhz2jpzu574u83vcx88twfu2zqx9t42lf9623ysqx3h23c7s2gwj7m

❯ sops updatekeys secrets.yml
2026/02/03 18:16:58 Syncing keys for file /Users/damonguo/Workspace/demo/repo/sops-demo/secrets.yml
The following changes will be made to the file's groups:
Group 1
    age1lz4xs2z4rwcd9t4g3ek7vlj49x7uqzjnug3l8996tac40y4saatsw0ezx9
+++ age1ckhckhz2jpzu574u83vcx88twfu2zqx9t42lf9623ysqx3h23c7s2gwj7m
Is this okay? (y/n):y
2026/02/03 18:17:10 File /Users/damonguo/Workspace/demo/repo/sops-demo/secrets.yml synced with new keys
```

以用户 Bob 的身份尝试已授权状态下解密

```plain
❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops_keys/bob.key

❯ sops --decrypt secrets.yml
db:
    username: super-secret
    password: ultra-secret
```

## 移除授权并校验

已授权的用户 Bob 可以将 Alice 的密钥移除，并添加 Jack 的授权

```plain
❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops_keys/bob.key

❯ vim .sops.yaml
creation_rules:
  - path_regex: ^secrets\.yml$
    age:
      - age1ckhckhz2jpzu574u83vcx88twfu2zqx9t42lf9623ysqx3h23c7s2gwj7m
      - age1h0ufdryerkpy39xkun9zd2hrece3g7nu9l63ws927cngwk633dcspuvgal

❯ sops updatekeys secrets.yml
2026/02/03 18:23:11 Syncing keys for file /Users/damonguo/Workspace/demo/repo/sops-demo/secrets.yml
The following changes will be made to the file's groups:
Group 1
    age1ckhckhz2jpzu574u83vcx88twfu2zqx9t42lf9623ysqx3h23c7s2gwj7m
+++ age1h0ufdryerkpy39xkun9zd2hrece3g7nu9l63ws927cngwk633dcspuvgal
--- age1lz4xs2z4rwcd9t4g3ek7vlj49x7uqzjnug3l8996tac40y4saatsw0ezx9
Is this okay? (y/n):y
2026/02/03 18:23:28 File /Users/damonguo/Workspace/demo/repo/sops-demo/secrets.yml synced with new keys
```

用户 Alice 无法再解密 secrets.yml

```plain
❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops_keys/alice.key

❯ sops --decrypt secrets.yml
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

用户 Bob 和 Jack 可以解密 secrets.yml

```plain
❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops_keys/jack.key
❯ sops --decrypt secrets.yml
db:
    username: super-secret
    password: ultra-secret

❯ export SOPS_AGE_KEY_FILE=/Users/damonguo/Workspace/demo/sops_keys/jack.key
❯ sops --decrypt secrets.yml
db:
    username: super-secret
    password: ultra-secret
```

查看加密后的 secrets.yml 文件内容

```plain
❯ cat secrets.yml
db:
    username: ENC[AES256_GCM,data:K4o7b88VYy1fiIRK,iv:WMPXoFF0aaxktEjaFxliYpsDgb77MVvbwviuwmYCRsk=,tag:qM3PzdjkyqYL2U+Ryhw/+Q==,type:str]
    password: ENC[AES256_GCM,data:SBIn28H5hlTNb0Xg,iv:BouoeNldrph5vph1ti2Y5Xny/qI5dQaFHCbsAFy/Ezo=,tag:X6SYXPgDU0R+WIVO0da+cA==,type:str]
sops:
    age:
        - recipient: age1ckhckhz2jpzu574u83vcx88twfu2zqx9t42lf9623ysqx3h23c7s2gwj7m
          enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBhV04ydEp2SENrTk8xN01r
            MjFMZHREWDZydDc2dlM2V1FoUXEzMGFQY3hrCjdkeGVyNi9xRzBscllsU21jMHRh
            OCtMcXNRUFZXbHN2TXFtb0ZmQ0pXVkEKLS0tIHVGOSswWExyRThCWElVYi9Sa2hV
            cmM2NlRhRDAzYTcyRktPVU1abzBib3cKxevxN88yTfShd8+7TdrLYfY53krYOYtk
            rnJbrrH0+owJhyyiAFgzyphvzfbC1IwJA4gNR3OMc+R1vwngtfS+hg==
            -----END AGE ENCRYPTED FILE-----
        - recipient: age1h0ufdryerkpy39xkun9zd2hrece3g7nu9l63ws927cngwk633dcspuvgal
          enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSA2bGFjeXQwc2hvcGE5c3pW
            ejgreFEzRVdhS2hqKzJ4M1BLdFJPLzlDSXpjCldrTTZSNUxtdk5BbXJYTHg5UHNw
            RWxpQURuZ0pWVDFxUGhYZnhPdCs3K00KLS0tIG8ybXVqT3QwQW85MmdENllQZU0z
            aW5NSEZBUWwrZDZBaHBRTUlBRExhQ00KV8F3UnarwNmFdNRdmYfMjgOha5yqYzvM
            b7AdSIKiVpZ92WgGDS7RJ4ouKYYkBQEmsaMFZwjqG9xGRRBkrI8YlA==
            -----END AGE ENCRYPTED FILE-----
    lastmodified: "2026-02-03T10:00:15Z"
    mac: ENC[AES256_GCM,data:5rbslKqxuIVbsilV3BFvlKw6BV2mUjGV0dmizTAXJgW5iC6n3I4ByGanc40lU/OjE02upvNo11NuoUtbDv7h1K+/XxFU7DlwMEJ7BGVdWU9Dq5fhf4eF2tcV5Q+Dw4JawUiMbBE25T3J0m+CMRx/Fb9KSRryYF7jb07l+QlTSrI=,iv:PasAhpZQI8h95vBu4szxxTyENYDgUimsYykS540svF8=,tag:/uHDwWrvqY6OYVjullgwhA==,type:str]
    unencrypted_suffix: _unencrypted
    version: 3.11.0
```

## 参考

https://blog.gitguardian.com/a-comprehensive-guide-to-sops/

