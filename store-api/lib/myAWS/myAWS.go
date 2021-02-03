package myAWS

import (
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
)

func DynamoDB() *dynamodb.DynamoDB {
	s := session.Must(session.NewSession())
	return dynamodb.New(s)
}
