import { faker } from "@faker-js/faker";

interface OrderItem {
  orderItemId: number;
  sku: string;
  quantity: number;
}

interface OrderHeader {
  orderId: number;
  orderGuid: string;
  description: string;
  firstName: string;
  lastName: string;
  delivery: string;
  items: OrderItem[];
}

let orderId = 0;
let orderItemId = 0;

function createRandomItems(): OrderItem {
  return {
    orderItemId: ++orderItemId,
    sku: faker.string.uuid().substring(0, 13),
    quantity: faker.number.int({ max: 10 }),
  };
}

function createRandomOrder(): OrderHeader {
  orderItemId = 0;
  return {
    orderId: ++orderId,
    orderGuid: faker.string.uuid(),
    description: faker.lorem.slug(5),
    firstName: faker.person.firstName(),
    lastName: faker.person.lastName(),
    delivery: faker.helpers.arrayElement(["Express", "Standard"]),
    items: faker.helpers.multiple(createRandomItems, {
      count: { min: 1, max: 10 },
    }),
  };
}

let orders: OrderHeader[] = faker.helpers.multiple(createRandomOrder, {
  count: 5,
});

console.log(JSON.stringify(orders));
