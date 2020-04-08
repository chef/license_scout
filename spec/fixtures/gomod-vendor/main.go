package main

import (
	"fmt"

	"github.com/gofrs/uuid"
)

func main() {
	u, _ := uuid.NewV4()
	fmt.Println(u)
}
