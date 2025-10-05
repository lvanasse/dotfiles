# SSH Key Setup for Your Git Accounts

This guide will help you set up SSH keys for your personal and work Git accounts on a new machine. Your NixOS config automatically handles the Git configuration based on directory, but you need to generate the SSH keys first.

## 1. Generate SSH Keys

Run these commands to generate separate SSH keys:

```bash
# Generate personal key for GitHub
ssh-keygen -t ed25519 -C "mail@ludovicvanasse.com" -f ~/.ssh/id_ed25519_personal

# Generate work key for Bitbucket
ssh-keygen -t ed25519 -C "lvanasse@luxaerobot.com" -f ~/.ssh/id_ed25519_work
```

## 2. Add Keys to SSH Agent

```bash
# Start SSH agent
eval "$(ssh-agent -s)"

# Add both keys
ssh-add ~/.ssh/id_ed25519_personal
ssh-add ~/.ssh/id_ed25519_work
```

## 3. Add Public Keys to Git Hosting Services

### Personal GitHub Account
1. Copy your personal public key:
   ```bash
   cat ~/.ssh/id_ed25519_personal.pub
   ```
2. Go to GitHub.com → Settings → SSH and GPG keys → New SSH key
3. Paste the public key and save

### Work Bitbucket Account
1. Copy your work public key:
   ```bash
   cat ~/.ssh/id_ed25519_work.pub
   ```
2. Go to Bitbucket.org → Personal settings → SSH keys → Add key
3. Paste the public key and save

## 4. Test the Configuration

```bash
# Test personal GitHub connection
ssh -T github-personal

# Test work Bitbucket connection  
ssh -T bitbucket-work

# Test default GitHub (should use personal)
ssh -T git@github.com
```

## 5. Directory Structure

Make sure your directories exist:
```bash
mkdir -p ~/Code/personal
mkdir -p ~/Code/work
```

## 6. Usage Examples

### Personal repositories (in ~/Code/personal/)
```bash
cd ~/Code/personal
git clone git@github.com:lvanasse/some-repo.git
# This will automatically use your personal account and SSH key
```

### Work repositories (in ~/Code/work/)
```bash
cd ~/Code/work  
git clone git@bitbucket-work:company/some-repo.git
# This will automatically use your work account and SSH key
```

## 7. Verify Configuration

You can check which account is being used:
```bash
# In personal directory
cd ~/Code/personal/some-repo
git config user.email  # Should show: mail@ludovicvanasse.com

# In work directory  
cd ~/Code/work/some-repo
git config user.email  # Should show: lvanasse@luxaerobot.com
```

## 8. Apply the Configuration

After setting up the SSH keys, apply your NixOS configuration:
```bash
# Apply the new configuration
nh os switch -H pc  # or laptop

# Or just apply Home Manager changes
home-manager switch --flake .#ludovic@pc  # or laptop
```

## Security Notes

- Never commit private keys to any repository
- Keep your SSH keys secure and backed up safely
- Consider using a password manager to store key passphrases
- The private keys stay on your local machine only

## Troubleshooting

If you have issues:
1. Check SSH agent is running: `ssh-add -l`
2. Verify key permissions: `ls -la ~/.ssh/`
3. Test SSH connections with verbose output: `ssh -vT github-personal`
4. Check git configuration: `git config --list --show-origin`