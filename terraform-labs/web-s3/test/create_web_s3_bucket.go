package test

import (
	"fmt"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestWebsiteBucket(t *testing.T) {
	awsRegion := "us-west-2"
	terraformDir := "/workspace"

	// Get the bucket name and website endpoint from the Terraform output
	bucketName := terraform.Output(t, terraformOptions, "bucket_name")
	websiteEndpoint := terraform.Output(t, terraformOptions, "website_endpoint")

	// Wait for the website to be available
	http_helper.HttpGetWithRetry(t, fmt.Sprintf("http://%s", websiteEndpoint), nil, 200, "Hello, World!", 30, 5*time.Second)

	// Validate that the bucket is serving the correct HTML
	url := fmt.Sprintf("http://%s.s3-website-%s.amazonaws.com", bucketName, awsRegion)
	expectedBody := "Welcome to our pizza shop!"
	http_helper.HttpGetWithRetry(t, url, nil, 200, expectedBody, 30, 5*time.Second)
}
