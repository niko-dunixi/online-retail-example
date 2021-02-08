package main

import (
	"context"
	"fmt"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"log"
	"store-api/lib"
	"store-api/lib/env"
	_ "store-api/lib/log"
	"store-api/lib/myAWS"
	"strings"
)

func main() {
	lambda.Start(Create)
}

func Create(ctx context.Context, createProductRequest lib.Product) (lib.Product, error) {
	log.Printf("invocation request: %+v", createProductRequest)
	dynamoDB := myAWS.DynamoDB()

	tableName := env.MustEnvString("TABLE_NAME")
	log.Printf("dynamodb table: %s", tableName)
	productKey := "product#" + createProductRequest.Vendor + "#" + createProductRequest.Name
	item := map[string]*dynamodb.AttributeValue{
		"key_hash":  {S: aws.String(productKey)},
		"key_range": {S: aws.String(productKey)},
	}
	if description := strings.TrimSpace(createProductRequest.Description); len(description) > 0 {
		item["description"] = &dynamodb.AttributeValue{S: aws.String(description)}
	}
	log.Printf("dynamodb put: %+v", item)
	response, err := dynamoDB.PutItemWithContext(ctx, &dynamodb.PutItemInput{
		ConditionExpression: aws.String("attribute_not_exists(#key_hash)"),
		ExpressionAttributeNames: map[string]*string{
			"#key_hash": aws.String("key_hash"),
		},
		Item:      item,
		TableName: aws.String(tableName),
	})
	if err != nil {
		if awsErr, ok := err.(awserr.Error); ok {
			switch awsErr.Code() {
			case dynamodb.ErrCodeConditionalCheckFailedException:
				err = fmt.Errorf(`vendor product already exists: %s %s`,
					createProductRequest.Vendor, createProductRequest.Name)
			}
		}
		log.Printf("dynamodb error: %+v", err)
		return lib.Product{}, err
	}
	log.Printf("dynamodb response: %+v", response)
	log.Printf("invocation response: %+v", createProductRequest)
	return createProductRequest, nil
}
