package env

import (
	"fmt"
	"log"
	"os"
)

func EnvString(key string) (string, bool) {
	return os.LookupEnv(key)
}

func MustEnvString(key string) string {
	value, ok := EnvString(key)
	if !ok {
		err := fmt.Errorf("environment variable '%s' was not set", key)
		log.Fatal(err)
	}
	return value
}
