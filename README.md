# What it does
- Pulls every 1080p and 2160p torrent from YTS, adds any you don't have to RD. 
- Does NOT select files
  - select the torrents in debridmediamanger and select 'reinsert' to auto select file(s). 

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
