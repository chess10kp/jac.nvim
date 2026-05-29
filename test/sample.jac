# test/sample.jac
# A simple Jac program to test LSP auto-start

walker test_walker {
    has name: str;
    has count: int;

    can greet with entry {
        print("Hello from Jac!");
        print(self.name);
    }
}
