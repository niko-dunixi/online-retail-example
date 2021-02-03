package main

import (
	"context"
	"fmt"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/google/uuid"
	"store-api/lib"
	"store-api/lib/env"
	_ "store-api/lib/log"
	"store-api/lib/myAWS"
)

func main() {
	lambda.Start(Create)
}

func Create(ctx context.Context, createProductRequest lib.Product) (lib.Product, error) {
	dynamoDB := myAWS.DynamoDB()

	tableName := env.MustEnvString("TABLE_NAME")
	itemUUID, err := uuid.NewRandom()
	if err != nil {
		return lib.Product{}, fmt.Errorf("could not create uuid: %v", err)
	}

	_, err = dynamoDB.PutItemWithContext(ctx, &dynamodb.PutItemInput{
		ConditionExpression: aws.String("attribute_not_exists(#item)"),
		ExpressionAttributeNames: map[string]*string{
			"#uuid": aws.String("uuid"),
			"#item": aws.String("item"),
		},
		Item: map[string]*dynamodb.AttributeValue{
			"#uuid": {
				S: aws.String(itemUUID.String()),
			},
			"#item": {
				S: aws.String("product#" + createProductRequest.Vendor + "#" + createProductRequest.Name),
			},
			"description": {
				S: aws.String(createProductRequest.Description),
			},
		},
		TableName: aws.String(tableName),
	})
	if err != nil {
		return lib.Product{}, fmt.Errorf("could not create product: %+v", err)
	}

	return createProductRequest, nil
}
