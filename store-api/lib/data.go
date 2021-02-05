package lib

import (
	"encoding/json"
	"fmt"
	"strings"
)

type Product struct {
	Vendor      string `json:"vendor"`
	Name        string `json:"name"`
	Description string `json:"description"`
}

var (
	ProductVendorMustBeString      = fmt.Errorf("vendor name must be string")
	ProductNameMustBeString        = fmt.Errorf("product name must be string")
	ProductDescriptionMustBeString = fmt.Errorf("product description must be string")
)
var (
	ProductVendorEmptyError = fmt.Errorf("vendor name cannot be empty")
	ProductNameEmptyError   = fmt.Errorf("product name cannot be empty")
)

func (p *Product) UnmarshalJSON(data []byte) error {
	jsonProduct := map[string]interface{}{}
	if err := json.Unmarshal(data, &jsonProduct); err != nil {
		return err
	}

	localProduct := Product{}

	vendor, ok := jsonProduct["vendor"].(string)
	if !ok {
		return ProductVendorMustBeString
	} else if strings.TrimSpace(vendor) == "" {
		return ProductVendorEmptyError
	}
	localProduct.Vendor = vendor

	name, ok := jsonProduct["name"].(string)
	if !ok {
		return ProductNameMustBeString
	} else if strings.TrimSpace(name) == "" {
		return ProductNameEmptyError
	}
	localProduct.Name = name

	if jsonProductDesc := jsonProduct["description"]; jsonProductDesc != nil {
		description, ok := jsonProduct["description"].(string)
		if !ok {
			return ProductDescriptionMustBeString
		}
		localProduct.Description = description
	}

	*p = localProduct
	return nil
}
