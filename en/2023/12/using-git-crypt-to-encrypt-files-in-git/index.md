# Using git-crypt to Encrypt Files in Git


git-crypt is a tool for encrypting and decrypting files that integrates seamlessly with Git repositories, allowing users to securely store and share sensitive data.

<!--more-->

---

## Install packages

Install git-crypt and gnupg

```plain
❯ brew install git-crypt gnupg
```

## Create directories

Create required directories to simulate multi-user collaboration

```plain
❯ mkdir -p /Users/damonguo/Workspace/demo/{repo,gnupg_keys,tmp}
❯ cd /Users/damonguo/Workspace/demo/
❯ ls -1
gnupg_keys
repo
tmp

❯ mkdir -p /Users/damonguo/Workspace/demo/gnupg_keys/{alice,bob,jack}
❯ chmod 700 /Users/damonguo/Workspace/demo/gnupg_keys/{alice,bob,jack}
❯ ls -l /Users/damonguo/Workspace/demo/gnupg_keys/
total 0
drwx------@ 2 damonguo  staff  64 Jan 28 11:28 alice
drwx------@ 2 damonguo  staff  64 Jan 28 11:28 bob
drwx------@ 2 damonguo  staff  64 Jan 28 11:28 jack
```

## Clone Git repository

Clone the demo repo for user Alice and initialize the git-crypt and secret.txt

```plain
❯ cd repo
❯ git clone git@github.com:mcsrainbow/git-crypt-demo.git
❯ mv git-crypt-demo git-crypt-demo_alice
❯ cd git-crypt-demo_alice

❯ git-crypt init
Generating key...

❯ echo "secret.txt filter=git-crypt diff=git-crypt" > .gitattributes
❯ cat .gitattributes
secret.txt filter=git-crypt diff=git-crypt
❯ git add .gitattributes
❯ git commit -m "chore: configure git-crypt"
[main f50794d] chore: configure git-crypt
 1 file changed, 1 insertion(+)
 create mode 100644 .gitattributes

❯ echo "TOP SECRET from Alice" > secret.txt
❯ cat secret.txt
TOP SECRET from Alice
❯ git add secret.txt
❯ git commit -m "feat: add encrypted secret"
[main e7f174b] feat: add encrypted secret
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 secret.txt
```

## Generate GPG keys

Generate GPG keys for Alice, Bob and Jack

```plain
❯ export GNUPGHOME=/Users/damonguo/Workspace/demo/gnupg_keys/alice
❯ gpg --batch --passphrase '' --quick-generate-key "Alice <alice@example.com>" rsa4096 sign,encrypt 10y
gpg: keybox '/Users/damonguo/Workspace/demo/gnupg_keys/alice/pubring.kbx' created
gpg: /Users/damonguo/Workspace/demo/gnupg_keys/alice/trustdb.gpg: trustdb created
gpg: directory '/Users/damonguo/Workspace/demo/gnupg_keys/alice/openpgp-revocs.d' created
gpg: revocation certificate stored as '/Users/damonguo/Workspace/demo/gnupg_keys/alice/openpgp-revocs.d/4EC36059B196849885E438499BAF6C28C32813A4.rev'
❯ ls /Users/damonguo/Workspace/demo/gnupg_keys/alice
openpgp-revocs.d    pubring.kbx    S.gpg-agent           S.gpg-agent.extra   trustdb.gpg
private-keys-v1.d   pubring.kbx~   S.gpg-agent.browser   S.gpg-agent.ssh

❯ export GNUPGHOME=/Users/damonguo/Workspace/demo/gnupg_keys/bob
❯ gpg --batch --passphrase '' --quick-generate-key "Bob <bob@example.com>" rsa4096 sign,encrypt 10y
gpg: keybox '/Users/damonguo/Workspace/demo/gnupg_keys/bob/pubring.kbx' created
gpg: /Users/damonguo/Workspace/demo/gnupg_keys/bob/trustdb.gpg: trustdb created
gpg: directory '/Users/damonguo/Workspace/demo/gnupg_keys/bob/openpgp-revocs.d' created
gpg: revocation certificate stored as '/Users/damonguo/Workspace/demo/gnupg_keys/bob/openpgp-revocs.d/B2E7F419BACD36339E1FECE34636D98424360512.rev'

❯ mkdir GNUPGHOME=/Users/damonguo/Workspace/demo/gnupg_keys/jack
❯ gpg --batch --passphrase '' --quick-generate-key "Jack <jack@example.com>" rsa4096 sign,encrypt 10y
gpg: keybox '/Users/damonguo/Workspace/demo/gnupg_keys/jack/pubring.kbx' created
gpg: /Users/damonguo/Workspace/demo/gnupg_keys/jack/trustdb.gpg: trustdb created
gpg: directory '/Users/damonguo/Workspace/demo/gnupg_keys/jack/openpgp-revocs.d' created
gpg: revocation certificate stored as '/Users/damonguo/Workspace/demo/gnupg_keys/jack/openpgp-revocs.d/4D1DED527513BE77A3546955107E34937CCFEA8E.rev'
```

## Grant permissions

Export the GPG public key of Bob for Alice to import

```plain
❯ export GNUPGHOME=/Users/damonguo/Workspace/demo/gnupg_keys/bob
❯ gpg --armor --export bob@example.com > /Users/damonguo/Workspace/demo/tmp/bob.pub
❯ file /Users/damonguo/Workspace/demo/tmp/bob.pub
/Users/damonguo/Workspace/demo/tmp/bob.pub: PGP public key block Public-Key
```

Add Alice and Bob as git-crypt collaborators and push to GitHub

```plain
❯ export GNUPGHOME=/Users/damonguo/Workspace/demo/gnupg_keys/alice
❯ git-crypt add-gpg-user alice@example.com
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
gpg: next trustdb check due at 2036-01-26
[main 46edf42] Add 1 git-crypt collaborator
 2 files changed, 4 insertions(+)
 create mode 100644 .git-crypt/.gitattributes
 create mode 100644 .git-crypt/keys/default/0/4EC36059B196849885E438499BAF6C28C32813A4.gpg

❯ gpg --import /Users/damonguo/Workspace/demo/tmp/bob.pub
gpg: key 4636D98424360512: public key "Bob <bob@example.com>" imported
gpg: Total number processed: 1
gpg:               imported: 1

❯ gpg --batch --yes --lsign-key bob@example.com

pub  rsa4096/4636D98424360512
     created: 2026-01-28  expires: 2036-01-26  usage: SCE
     trust: unknown       validity: unknown
[ unknown] (1). Bob <bob@example.com>


pub  rsa4096/4636D98424360512
     created: 2026-01-28  expires: 2036-01-26  usage: SCE
     trust: unknown       validity: unknown
 Primary key fingerprint: B2E7 F419 BACD 3633 9E1F  ECE3 4636 D984 2436 0512

     Bob <bob@example.com>

This key is due to expire on 2036-01-26.
Are you sure that you want to sign this key with your
key "Alice <alice@example.com>" (9BAF6C28C32813A4)

The signature will be marked as non-exportable.

❯ git-crypt add-gpg-user bob@example.com
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   1  trust: 0-, 0q, 0n, 0m, 0f, 1u
gpg: depth: 1  valid:   1  signed:   0  trust: 1-, 0q, 0n, 0m, 0f, 0u
gpg: next trustdb check due at 2036-01-26
[main c09d72d] Add 1 git-crypt collaborator
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 .git-crypt/keys/default/0/B2E7F419BACD36339E1FECE34636D98424360512.gpg

❯ git-crypt status
not encrypted: .git-crypt/.gitattributes
not encrypted: .git-crypt/keys/default/0/4EC36059B196849885E438499BAF6C28C32813A4.gpg
not encrypted: .git-crypt/keys/default/0/B2E7F419BACD36339E1FECE34636D98424360512.gpg
not encrypted: .gitattributes
not encrypted: README.md
    encrypted: secret.txt

❯ git push origin main
Enumerating objects: 22, done.
Counting objects: 100% (22/22), done.
Delta compression using up to 10 threads
Compressing objects: 100% (15/15), done.
Writing objects: 100% (21/21), 3.28 KiB | 1.64 MiB/s, done.
Total 21 (delta 3), reused 0 (delta 0), pack-reused 0 (from 0)
remote: Resolving deltas: 100% (3/3), done.
To github.com:mcsrainbow/git-crypt-demo.git
   3beff32..c09d72d  main -> main
```

## View encrypted file

View encrypted secret.txt as `View raw` on [GitHub](https://github.com/mcsrainbow/git-crypt-demo/blob/main/secret.txt)

{{< image src="encrypted_secret_txt.png" alt="encrypted_secret_txt" width=800 >}}

## Verify permissions

Bob cannot view the encrypted secret.txt without unlock

```plain
❯ cd ..
❯ export GNUPGHOME=/Users/damonguo/Workspace/demo/gnupg_keys/bob
❯ git clone git@github.com:mcsrainbow/git-crypt-demo.git
❯ mv git-crypt-demo git-crypt-demo_bob
❯ cd git-crypt-demo_bob
❯ file secret.txt
secret.txt: data
❯ cat secret.txt
GITCRYPT
```

Jack cannot unlock the encrypted secret.txt without being granted

```plain
❯ export GNUPGHOME=/Users/damonguo/Workspace/demo/gnupg_keys/jack
❯ git-crypt unlock
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
gpg: next trustdb check due at 2036-01-26
Error: no GPG secret key available to unlock this repository.
To unlock with a shared symmetric key instead, specify the path to the symmetric key as an argument to 'git-crypt unlock'.
```

Bob can unlock and lock the secret.txt

```plain
❯ export GNUPGHOME=/Users/damonguo/Workspace/demo/gnupg_keys/bob
❯ git-crypt unlock
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
gpg: next trustdb check due at 2036-01-26
❯ cat secret.txt
TOP SECRET from Alice

❯ git-crypt lock
❯ cat secret.txt
GITCRYPT
```

## Remove permissions

Bob can remove the Alice GPG key from repo

```plain
❯ git log | grep 'Add 1 git-crypt collaborator' -A5 | grep -B1 alice@example.com
        4EC36059B196849885E438499BAF6C28C32813A4
            Alice <alice@example.com>

❯ rm .git-crypt/keys/default/0/4EC36059B196849885E438499BAF6C28C32813A4.gpg
❯ git add -u
❯ git commit -m "chore: remove git-crypt access for Alice"
[main bf48d82] chore: remove git-crypt access for Alice
 1 file changed, 0 insertions(+), 0 deletions(-)
 delete mode 100644 .git-crypt/keys/default/0/4EC36059B196849885E438499BAF6C28C32813A4.gpg
❯ git push
```

Alice cannot unlock the secret.txt after re-cloning the repository

```plain
❯ cd ..
❯ export GNUPGHOME=/Users/damonguo/Workspace/demo/gnupg_keys/alice
❯ git clone git@github.com:mcsrainbow/git-crypt-demo.git
❯ mv git-crypt-demo git-crypt-demo_noalice
❯ cd git-crypt-demo_noalice
❯ git-crypt status
not encrypted: .git-crypt/.gitattributes
not encrypted: .git-crypt/keys/default/0/B2E7F419BACD36339E1FECE34636D98424360512.gpg
not encrypted: .gitattributes
not encrypted: README.md
    encrypted: secret.txt
❯ cat secret.txt
GITCRYPT
❯ git-crypt unlock
Error: no GPG secret key available to unlock this repository.
To unlock with a shared symmetric key instead, specify the path to the symmetric key as an argument to 'git-crypt unlock'.
```

## Complete journey

View the complete git commits

```plain
❯ git log
commit bf48d82e3ce40e237465e2af608b0ff990eb6735 (HEAD -> main, origin/main, origin/HEAD)
Author: mcsrainbow <guosuiyu@gmail.com>
Date:   Wed Jan 28 11:44:31 2026 +0800

    chore: remove git-crypt access for Alice

commit c09d72da79784054ebf2b2b8c5d5bb0a878c02c0
Author: mcsrainbow <guosuiyu@gmail.com>
Date:   Wed Jan 28 11:39:44 2026 +0800

    Add 1 git-crypt collaborator

    New collaborators:

        B2E7F419BACD36339E1FECE34636D98424360512
            Bob <bob@example.com>

commit 46edf42fc7ca6a658c874ae196ba4f75ac2d2aff
Author: mcsrainbow <guosuiyu@gmail.com>
Date:   Wed Jan 28 11:36:25 2026 +0800

    Add 1 git-crypt collaborator

    New collaborators:

        4EC36059B196849885E438499BAF6C28C32813A4
            Alice <alice@example.com>

commit e7f174b8cd6b10fc5837b89892481ed08b139398
Author: mcsrainbow <guosuiyu@gmail.com>
Date:   Wed Jan 28 11:31:56 2026 +0800

    feat: add encrypted secret

commit f50794db3651b72ee56c91bbdb25a021a768c691
Author: mcsrainbow <guosuiyu@gmail.com>
Date:   Wed Jan 28 11:31:40 2026 +0800

    chore: configure git-crypt

commit 3beff32096f2b50d2f012c6ba5e68cba1a0af5fb
Author: Dong Guo / Damon <guosuiyu@gmail.com>
Date:   Wed Jan 28 11:23:25 2026 +0800

    Initial commit
```

## References

https://buddy.works/guides/git-crypt

## Recommended

A solution with more convenient private key management, more intuitive operations, and easier integration with CI: [Using SOPS + age to Encrypt Files](/en/2026/02/using-sops-age-to-encrypt-files/)

