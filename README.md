# What it does
- Pulls every 1080p and 2160p torrent from YTS
- Adds any you don't have to RD.
  - Sleeps for 60s if API limited
  - Outputs to failed.txt if unhandled error (not API limit)
- Does NOT select files
  - Use DebridMediaManager to reinsert pending torrents, it finds cached ones quicker

# Instructions
Run rd.sh(run it a few times as if there's errors other than '34' rate limit, it'll keep the torrent in the main dir and you can retry)
```
curl https://raw.githubusercontent.com/Reasonable-Grape2698/yts-rd/refs/heads/main/rd.sh | bash -s -- -a APIKEY
```

| Flag     | Description                                   |
| -------- | --------------------------------------------- |
| -a       | RealDebrid API key                            |
| -r       | RealDebrid hash file (If already available)   |
| -y       | YTS hash file (If already available)          |
| -l       | Language (defaults to en)                     |

# Outputs
yts.txt - YTS hashlist
rd.txt - RealDebrid hashlist
unique.txt - YTS torrents missing from your RD
failed.txt - Torrents which failed after multiple tries
