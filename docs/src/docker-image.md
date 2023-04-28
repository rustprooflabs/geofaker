# Docker image

> Warning: This project is in early development!  Things will be changing over the first few releases (e.g. before 0.5.0).

## Building the image

Build latest.  Occasionally run with `--no-cache` to force some software updates.  

```bash
docker pull rustprooflabs/pgosm-flex:latest
docker build -t rustprooflabs/geo-faker:latest .
```


```bash
docker push rustprooflabs/geo-faker:latest
```
