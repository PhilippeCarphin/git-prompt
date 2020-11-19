Download with 
```
wget https://gitlab.science.gc.ca/phc001/git-prompt/raw/master/git-prompt.sh
```
and simply source it from your `~/.profile` or `~/.profile.d/interactive/post`.

Shows
```
 0 [phc001@hpcr4-in ~/workspace] $ cd a-git-repo/somedir
 0 [phc001@hpcr4-in a-git-repo/somedir (master) 2d4h3m] $ ...
```

Based on code from the Agnoster theme for zsh shell and official git-prompt.sh
(https://github.com/git/git/blob/master/contrib/completion/git-prompt.sh).

What this does differently is
- Allows to customize colors easily
- Shows exit code of previous command
- Colors of the git part change based on the state of the repo
- Shows time since last commit when files are modified
- Shows truncates the directory to only shoe where you are within the repo.
  Shortens `/A/B/C/repo_root/D/E/F` to `repo_root/D/E/F`
  If you are not in a git repo, it will show what a prompt string normally
  shows.

Customization

The first function of the script centralizes all the color settings.  Change the
values of the variables defining the colors for the prompt.

