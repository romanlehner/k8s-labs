# Work with terraform an localstack


## How to run it

```bash
# start localstack
docker compose up -d

# run terraform
alias dtf="docker run --rm --network localstack -it -v $(pwd):/workspace -w /workspace hashicorp/terraform:latest"

dtf init
dtf apply

# verify the bucket object exists with aws cli
alias daws="docker run --rm -it --network localstack -e AWS_ACCESS_KEY_ID=test -e AWS_SECRET_ACCESS_KEY=test amazon/aws-cli --endpoint-url=http://localstack:4566"

daws s3 ls
daws s3 ls s3://example-bucket --region=us-east-1
```

Verify the bucket serves the website in your browser with this [bucket verification link](http://localhost:4566/example-bucket/index.html).


