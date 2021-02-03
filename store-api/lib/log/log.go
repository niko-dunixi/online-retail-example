package log

import (
	"log"
	"os"
)

func init() {
	log.New(os.Stderr, "", 0)
}
