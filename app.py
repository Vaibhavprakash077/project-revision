# app.py

def get_name_length(name: str) -> int:
    """Return the number of characters in the given name."""
    return len(name)

def main():
    # Interactive part (not tested in CI)
    name = input("Enter your name: ")
    print(f"Hello, {name}! Welcome to my Git + GitHub Actions practice app.")
    print(f"Did you know? Your name has {get_name_length(name)} characters.")

if __name__ == "__main__":
    main()

print("HELLO")
