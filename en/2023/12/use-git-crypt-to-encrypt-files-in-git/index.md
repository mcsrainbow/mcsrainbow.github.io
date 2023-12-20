# Use git-crypt to encrypt files in Git


git-crypt is a tool for encrypting and decrypting files that integrates seamlessly with Git repositories, allowing users to securely store and share sensitive data.

<!--more-->


## Install git-crypt

```plain
❯ brew install git-crypt
```

## Initialize git-crypt and back up the encryption key

```plain
❯ git-crypt init
Generating key...
❯ git-crypt export-key /Users/damonguo/Workspace/keys/git-crypt-v1.key
❯ diff .git/git-crypt/keys/default /Users/damonguo/Workspace/keys/git-crypt-v1.key

❯ echo "git-crypt/api.key filter=git-crypt diff=git-crypt" > .gitattributes
❯ git add .gitattributes
❯ git commit -m "feat: tell git-crypt to encrypt git-crypt/api.key"
❯ git push
```

## Create git-crypt demo files

```plain
❯ mkdir git-crypt
❯ echo "This is some text" > git-crypt/file.txt
❯ echo "dummy value" > git-crypt/api.key
❯ git add git-crypt
❯ git commit -m "feat: add git-crypt demo files"
❯ git push
```

## Verify encryption and decryption status

Use the `git-crypt status` command to view the server side encryption and decryption status

```plain
❯ git-crypt status git-crypt
    encrypted: git-crypt/api.key
not encrypted: git-crypt/file.txt
```

View the server side encryption and decryption status on the `GitLab Web`

{{< image src="git_crypt_encrypted_file.jpg" alt="git_crypt_encrypted_file" width=800 >}}

Encrypt and decrypt the `git-crypt/api.key` locally with `git-crypt lock/unlock` commands

```plain
❯ git-crypt lock
❯ file git-crypt/api.key
git-crypt/api.key: data

❯ git-crypt unlock /Users/damonguo/Workspace/keys/git-crypt-v1.key
❯ file git-crypt/api.key
git-crypt/api.key: ASCII text
❯ cat git-crypt/api.key
dummy value
```

## Working in team with git-crypt

Share the exported encryption key `/Users/damonguo/Workspace/keys/git-crypt-v1.key` with team members in a secure way.

Then they can import encryption key and decrypt the repository by command: `git-crypt unlock /path/to/git-crypt-v1.key`.

## Renew the git-crypt encryption key

Create a new git-crypt encryption key

```plain
❯ git-crypt unlock /Users/damonguo/Workspace/keys/git-crypt-v1.key
❯ rm -rf .git/git-crypt/keys
❯ git-crypt init
Generating key...
❯ git-crypt export-key /Users/damonguo/Workspace/keys/git-crypt-v2.key
❯ diff .git/git-crypt/keys/default /Users/damonguo/Workspace/keys/git-crypt-v2.key
```

Trigger an update and apply the new git-crypt encryption key.

```plain
❯ echo "new dummy value" > git-crypt/api.key
❯ git add git-crypt/api.key
❯ git commit -m "feat: update api.key with new git-crypt encryption key"
❯ git push
```

Share the new git-crypt encryption key `/Users/damonguo/Workspace/keys/git-crypt-v2.key` with team members in a secure way.

Then ask them to hold on the git push and pull actions, import the new encryption key first: `git-crypt unlock /path/to/git-crypt-v2.key`.

## References

https://buddy.works/guides/git-crypt

