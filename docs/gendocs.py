import os
import sys

class Merger:
    def __init__(self, path, outfile):
        self.path = path
        self.outfile = outfile

    def _get_instructions(self):
        instructions = set()

        for file in os.listdir(self.path):
            if not file.startswith("fcl"): continue

            filename = file[3:] # Strip off 'fct'
            filename = filename.replace("Zero", "0")

            # Not an instruction
            if filename[0].islower(): continue

            name = ""
            for c in filename:
                if c.islower():
                    break
                name += c

            if name not in instructions:
                instructions.add(name)

        return instructions

    def _merge_files(self, files, out):
        for file in files:
            with open(os.path.join(self.path, file), "r") as f:
                out.write(f.read())
                out.write("\n")

    def generate(self):
        instructions = self._get_instructions()

        instruction_commands = {}
        for instruction in instructions:
            sail_instr_name = instruction
            sail_instr_name = sail_instr_name.replace("0", "Zero")
            sail_instr_name = "fcl" + sail_instr_name

            instruction_commands[instruction] = []
            with open(os.path.join(self.path, "commands.tex"), "r") as f:
                for line in f:
                    if sail_instr_name in line:
                        command = line.split("{")[1].split("}")[0]
                        instruction_commands[instruction].append(command)

        with open(self.outfile, "w+") as f:
            with open("gameboy-template.tex", "r") as temp:
                f.write(temp.read())

            for instruction, commands in instruction_commands.items():
                f.write(f"\subsection{'{'}{instruction}{'}'}\n")
                for command in commands:
                    f.write(f"{command}\n")

            f.write("\end{document}")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(f"usage: {sys.argv[0]} <in-path> <out-file>")
        sys.exit(1)
    m = Merger(sys.argv[1], sys.argv[2])
    m.generate()