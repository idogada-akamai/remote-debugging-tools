from argparse import ArgumentParser, Namespace

import inquirer


def main(options: list[str], question: str, result_file: str):
    answer_key = "answer"  # The answer is returned as a dict under this key
    questions = [
        inquirer.List("answer", message=question, choices=options),
    ]

    answers = inquirer.prompt(questions)
    print(answers[answer_key])
    # Write result to file
    with open(result_file, "w") as file:
        file.write(answers[answer_key])


def parse_args() -> Namespace:
    parser = ArgumentParser("Picker wrapper")
    parser.add_argument(
        "-o",
        "--options",
        nargs="+",
        required=True,
        help="The list of options to display the user",
    )
    parser.add_argument(
        "-q",
        "--question",
        required=True,
        help="The question to display the user before the list of options",
    )
    parser.add_argument("--result-file", default="selection.txt")
    return parser.parse_args()


if __name__ == "__main__":
    args_namespace = parse_args()
    main(
        options=args_namespace.options,
        question=args_namespace.question,
        result_file=args_namespace.result_file,
    )
