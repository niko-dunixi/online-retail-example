package lib

import (
	"encoding/json"
	"testing"
)

var testCases = []struct {
	jsonString      string
	expectedProduct Product
	expectedErr     error
}{
	{
		jsonString:  `{"vendor": null, "name": "name", "description": null}`,
		expectedErr: ProductVendorMustBeString,
	},
	{
		jsonString:  `{"vendor": "", "name": "name", "description": null}`,
		expectedErr: ProductVendorEmptyError,
	},
	{
		jsonString:  `{"vendor": "vendor", "name": null, "description": null}`,
		expectedErr: ProductNameMustBeString,
	},
	{
		jsonString:  `{"vendor": "vendor", "name": "", "description": null}`,
		expectedErr: ProductNameEmptyError,
	},
	{
		jsonString: `{"vendor": "vendor", "name": "name", "description": "something cool"}`,
		expectedProduct: Product{
			Vendor:      "vendor",
			Name:        "name",
			Description: "something cool",
		},
	},
	{
		jsonString: `{"vendor": "vendor", "name": "name", "description": ""}`,
		expectedProduct: Product{
			Vendor:      "vendor",
			Name:        "name",
			Description: "",
		},
	},
	{
		jsonString: `{"vendor": "vendor", "name": "name", "description": null}`,
		expectedProduct: Product{
			Vendor:      "vendor",
			Name:        "name",
			Description: "",
		},
	},
}

func TestParseProduct(t *testing.T) {
	for _, currentTestCase := range testCases {
		product := Product{}
		err := json.Unmarshal([]byte(currentTestCase.jsonString), &product)
		if err != currentTestCase.expectedErr {
			t.Errorf(`expected error "%+v", but got "%+v"`, currentTestCase.expectedErr, err)
			return
		}
		if product.Vendor != currentTestCase.expectedProduct.Vendor {
			t.Errorf(`expected vendor "%v" but got "%v"`,
				currentTestCase.expectedProduct.Vendor, product.Vendor)
		}
		if product.Name != currentTestCase.expectedProduct.Name {
			t.Errorf(`expected name "%v" but got "%v"`,
				currentTestCase.expectedProduct.Name, product.Name)
		}
		if product.Description != currentTestCase.expectedProduct.Description {
			t.Errorf(`expected description "%v" but got "%v"`,
				currentTestCase.expectedProduct.Description, product.Description)
		}
	}
}
