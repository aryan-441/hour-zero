"""Deterministic, standard-library-only bank: 550 regular + 60 boss questions.

Fifteen arithmetic families and ten families for each other regular category, across all five tiers.
Run this file to regenerate data/question_bank.json; the game uses the JSON.
"""
import hashlib
import itertools
import json
import math
import random
from collections import Counter
from pathlib import Path

RNG = random.Random(20261021)
QUESTIONS = []
SIGNATURES = set()
SCALES = {"GREEN": 1.0, "YELLOW": .92, "ORANGE": .82, "RED": .72, "CRITICAL": .58}
SYMBOLS = "STAR MOON WAVE CROSS RING LEAF CUBE ARROW SUN GEM".split()
NAMES = "NOVA ECHO VEGA ATLAS ORBIT LYRA PULSE COMET".split()
ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ"


def add(category, family, tier, prompt, answer, explanation, hint, *, boss=False, **extra):
    signature = " ".join((prompt + "|" + extra.get("stimulus", "")).lower().split())
    assert signature not in SIGNATURES, f"Duplicate content: {prompt}"
    SIGNATURES.add(signature)
    assert isinstance(answer, (str, int)) and str(answer).strip()
    base = min(42, {"arithmetic": 13, "patterns": 16, "logic": 22, "memory": 14, "attention": 13}[category] + 2 * tier)
    if family == "code_deduction":
        base = 32 + tier * 2
    if boss:
        base = 38
    q = {"id": category[:3].upper() + "_" + hashlib.sha256(signature.encode()).hexdigest()[:12],
         "category": category, "subcategory": family, "difficulty": tier,
         "type": "numeric_input" if isinstance(answer, int) else "text_input",
         "prompt": prompt, "answer": answer, "accepted_answers": [answer],
         "time_limit_seconds": base,
         "time_limits_by_exposure": {band: max(6, round(base * scale)) for band, scale in SCALES.items()},
         "base_points": 100 + (tier - 1) * 25, "credit_reward": 20 + tier * 5,
         "explanation": explanation, "hint": hint, "intel_hint": hint,
         "tags": [category, family], "validated": True, "boss_eligible": boss}
    if boss:
        q["boss_time_limits_by_exposure"] = {band: max(6, round(48 * scale)) for band, scale in SCALES.items()}
    q.update(extra)
    QUESTIONS.append(q)


def arithmetic(family, tier, variant):
    a, b, c = RNG.randint(12, 25 + 15*tier), RNG.randint(3, 10+tier), RNG.randint(2, 8+tier)
    if family == 0:
        start = a*5 + variant
        incoming, sent = b*3, c*2
        return ("inventory_balance", f"A cache holds {start} files. {incoming} arrive and {sent} are removed. How many remain?", start+incoming-sent,
                f"{start} + {incoming} - {sent} = {start+incoming-sent}.", "Add the arriving files before subtracting the removed files.")
    if family == 1:
        price, pct = 20*a, RNG.choice([5, 10, 15, 20, 25, 35, 40])
        return ("discount", f"An upgrade costs {price} credits before a {pct}% discount. What is the final price?", price*(100-pct)//100,
                f"The discount is {price*pct//100}; subtract it from {price}.", "Find the discount first, then subtract it from the original price.")
    if family == 2:
        denominator = RNG.choice([3, 4, 5, 6, 8])
        numerator = RNG.randint(1, denominator-1)
        total = denominator*a
        return ("fraction_of_total", f"A transfer contains {total} blocks. {numerator}/{denominator} are encrypted. How many blocks are encrypted?", a*numerator,
                f"{total} divided by {denominator} is {a}; multiply by {numerator} to get {a*numerator}.", "Divide by the denominator, then multiply by the numerator.")
    if family == 3:
        return ("unit_rate", f"A scanner checks {a*b} files in {b} minutes at a constant rate. How many files can it check in {c} minutes?", a*c,
                f"The rate is {a} files per minute, giving {a*c} in {c} minutes.", "Work out the number processed in one minute.")
    if family == 4:
        return ("missing_operand", f"Solve for x: {b}x + {c} = {b*a+c}.", a,
                f"Subtract {c} and divide by {b}: x = {a}.", "Undo addition before undoing multiplication.")
    if family == 5:
        start = RNG.randint(8*60, 17*60)
        duration = a+b*2
        end = start+duration
        return ("elapsed_time", f"A scan starts at {start//60:02d}:{start%60:02d} and ends at {end//60:02d}:{end%60:02d} the same day. How many minutes does it take?", duration,
                f"Convert both times to minutes after midnight: {end} - {start} = {duration}.", "Count to the next full hour, then add the remaining minutes.")
    if family == 6:
        return ("weighted_total", f"There are {b} batches of {a} packets and {c} batches of {b+4} packets. How many packets in total?", b*a+c*(b+4),
                f"The two subtotals are {b*a} and {c*(b+4)}; their sum is {b*a+c*(b+4)}.", "Multiply each batch size by its batch count, then add.")
    if family == 7:
        numbers = [a, a+b, a-c]
        mean = a+RNG.randint(1, 6)
        missing = mean*4-sum(numbers)
        return ("missing_mean", f"Four values have mean {mean}. Three are {', '.join(map(str,numbers))}. What is the fourth?", missing,
                f"The total must be {mean*4}. Subtract the known total {sum(numbers)} to get {missing}.", "Multiply the mean by four to find the required total.")
    if family == 8:
        count = a*3+variant
        return ("remainder", f"{count} packets are grouped into batches of {b}. How many packets are left outside the full batches?", count%b,
                f"{count} = {count//b} x {b} + {count%b}.", "Find the largest multiple of the batch size that fits.")
    if family == 9:
        numerator = 2*a+b*c
        return ("nested_expression", f"Calculate ({numerator} - {b} x {c}) / 2.", a,
                f"The product is {b*c}; subtract it to get {2*a}, then divide by 2.", "Do the multiplication inside the parentheses first.")
    if family == 10:
        price = a*20
        percent = RNG.choice([5, 10, 15, 20, 25, 30, 40])
        final_price = price*(100+percent)//100
        return ("percentage_increase", f"A tool costs {price} credits. Its price rises by {percent}%. What is the new price?", final_price,
                f"The increase is {price*percent//100} credits, so the new price is {price} + {price*percent//100} = {final_price}.", "Find the percentage increase, then add it to the starting price.")
    if family == 11:
        first = RNG.randint(2, 8+tier)
        second = RNG.randint(2, 8+tier)
        scale = RNG.randint(3, 10)
        total = (first+second)*scale
        share = first*scale
        return ("ratio_share", f"A cache of {total} files is split between two teams in the ratio {first}:{second}. How many files go to the first team?", share,
                f"There are {first+second} total ratio parts. Each part is {scale} files, so the first team gets {first} x {scale} = {share}.", "Add the ratio parts, divide the total by that sum, then multiply by the first part.")
    if family == 12:
        length = RNG.randint(8, 30+5*tier)
        width = RNG.randint(3, 12+2*tier)
        perimeter = 2*(length+width)
        return ("rectangle_perimeter", f"A rectangular room is {length} m long and {width} m wide. How many metres of cable are needed to trace its perimeter once?", perimeter,
                f"A rectangle has two lengths and two widths: 2 x {length} + 2 x {width} = {perimeter} m.", "Add one length and one width, then double that sum.")
    if family == 13:
        principal = a*100
        rate = RNG.choice([4, 5, 8, 10, 12, 15, 20])
        years = c
        interest = principal*rate*years//100
        return ("simple_interest", f"A reserve of {principal} credits earns {rate}% simple interest per year for {years} years. How many interest credits are earned?", interest,
                f"Simple interest is principal x rate x time: {principal} x {rate}/100 x {years} = {interest} credits.", "Use the original reserve for each year's interest; simple interest does not compound.")
    if family == 14:
        count = RNG.choice([3, 4, 5, 6, 7, 8])
        first = RNG.randint(3, 20+3*tier)
        total = count*first+count*(count-1)//2
        offset_sum = count*(count-1)//2
        largest = first+count-1
        return ("consecutive_sum", f"{count} consecutive whole-number access codes have a total of {total}. What is the largest code?", largest,
                f"Subtract the offsets 0 through {count-1}: {total} - {offset_sum} = {count*first}. Divide by {count} to get first code {first}; largest is {largest}.", "Subtract the offsets from zero through n-1, divide by the count, then add n-1.")
    raise ValueError(f"Unknown arithmetic family: {family}")


def patterns(family, tier, variant):
    start, step = RNG.randint(2, 25+5*tier), RNG.randint(2, 5+tier)
    if family == 0:
        step *= RNG.choice([-1, 1])
        seq = [start+i*step for i in range(7)]
        name, rule = "constant_step", f"Add {step} at each step."
    elif family == 1:
        ratio = RNG.choice([2, 3])
        seq = [start*ratio**i for i in range(6)]
        name, rule = "geometric", f"Multiply each number by {ratio}."
    elif family == 2:
        increment = RNG.randint(1, tier+2)
        seq = [start]
        for i in range(6): seq.append(seq[-1]+step+i*increment)
        name, rule = "growing_gaps", f"The gaps start at {step} and increase by {increment}."
    elif family == 3:
        subtract = RNG.randint(1, step-1)
        seq = [start]
        for i in range(6): seq.append(seq[-1]+(step if i%2==0 else -subtract))
        name, rule = "alternating_operations", f"Alternate adding {step} and subtracting {subtract}."
    elif family == 4:
        other, other_step = start+RNG.randint(8, 30), step+RNG.randint(1, 6)
        seq = [start+(i//2)*step if i%2==0 else other+(i//2)*other_step for i in range(7)]
        name, rule = "interleaved", f"Odd positions increase by {step}; even positions increase by {other_step}. The seventh term is from the odd positions."
    elif family == 5:
        k, offset = RNG.randint(1, 8+tier), RNG.randint(-3, 10)
        seq = [(k+i)**2+offset for i in range(6)]
        name, rule = "shifted_squares", f"These are consecutive squares with {offset} added."
    elif family == 6:
        seq = [start, start+step]
        for _ in range(5): seq.append(sum(seq[-2:]))
        name, rule = "sum_previous_two", "Each number is the sum of the two before it."
    elif family == 7:
        multiplier = RNG.choice([2, 3])
        seq = [start]
        for _ in range(5): seq.append(seq[-1]*multiplier+step)
        name, rule = "multiply_add", f"Multiply by {multiplier}, then add {step}."
    elif family == 8:
        k = RNG.randint(2, 8+tier)
        seq = [start+(k+i)*(k+i+1)//2 for i in range(6)]
        name, rule = "triangular_gaps", "The difference increases by one each time."
    else:
        alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        seq = [alphabet[(start+i*step)%26] for i in range(7)]
        return ("letter_steps", f"Letters advance by a fixed number of places, wrapping after Z. What comes next? {', '.join(seq[:-1])}, ?", seq[-1],
                f"Advance {step} places each time; the next letter is {seq[-1]}.", "Count alphabet positions between neighbouring letters, including wraparound.")
    return name, f"What number comes next? {', '.join(map(str,seq[:-1]))}, ?", seq[-1], rule+f" Next: {seq[-1]}.", rule


def logic(family, tier, variant):
    names = RNG.sample(NAMES, 4)
    if family == 0:
        order = names[:]
        clues = [f"{order[i]} runs before {order[i+1]}" for i in range(3)]
        RNG.shuffle(clues)
        target = RNG.randrange(4)
        valid = [p for p in itertools.permutations(order) if all(p.index(order[i])<p.index(order[i+1]) for i in range(3))]
        assert valid == [tuple(order)]
        return ("ordering", "Four jobs run one at a time. "+"; ".join(clues)+f". Which position is {order[target]} in (count from 1)?", target+1,
                "The only possible order is "+", ".join(order)+f"; {order[target]} is in position {target+1}.", "Join the before-relations into a single chain.")
    if family == 1:
        a,b,c = RNG.sample(range(3, 10+5*tier), 3)
        return ("parallel_scheduling", f"Jobs {names[0]} ({a} min) and {names[1]} ({b} min) start together. {names[2]} ({c} min) can start only when BOTH finish. How many minutes until all three finish?", max(a,b)+c,
                f"Wait for the longer first job: max({a}, {b}) + {c} = {max(a,b)+c}.", "The parallel jobs overlap; use the slower one, then add the dependent job.")
    if family == 2:
        rooms = names[:3]
        predicates = [(r,positive) for r in rooms for positive in [False,True]]
        for _ in range(1000):
            claims = RNG.sample(predicates, 3)
            count = RNG.choice([1,2])
            valid = [r for r in rooms if sum((r==place)==positive for place,positive in claims)==count]
            if len(valid)==1: break
        else: raise AssertionError("No unique truth puzzle")
        statements = "; ".join(f"({i+1}) the key is {'in' if positive else 'not in'} {place}" for i,(place,positive) in enumerate(claims))
        return ("truth_conditions", f"A key is in {', '.join(rooms)}. Exactly {count} of these statements are true: {statements}. Where is the key?", valid[0],
                f"Testing each of the three rooms leaves only {valid[0]} with exactly {count} true statements.", "For each possible room, count true statements, including the negative ones.")
    if family == 3:
        alphabet = "123456"
        pool = [''.join(p) for p in itertools.permutations(alphabet,3)]
        secret = RNG.choice(pool)
        def score(code, guess):
            exact = sum(x==y for x,y in zip(code,guess))
            return exact, len(set(code)&set(guess))-exact
        guesses = pool[:]
        RNG.shuffle(guesses)
        candidates, clues = pool[:], []
        for guess in guesses:
            exact, misplaced = score(secret,guess)
            kept = [code for code in candidates if score(code,guess)==(exact,misplaced)]
            if len(kept)==len(candidates): continue
            clues.append(f"{guess}: {exact} in the right place, {misplaced} correct but misplaced")
            candidates = kept
            if len(candidates)==1: break
        assert candidates == [secret]
        return ("code_deduction", "A 3-digit code uses distinct digits from 1 to 6. "+"; ".join(clues)+". What is the code?", secret,
                f"Checking all 120 possible distinct-digit codes against every clue leaves {secret}.", "Use any zero counts to eliminate digits, then enforce exact positions.")
    if family == 4:
        a,b,c = names[:3]
        options = [
            (f"Every {a} token is {b}. Every {b} token is {c}. Must every {a} token be {c}?", "Yes", "Apply both universal rules in sequence."),
            (f"Every {a} token is {b}. Some {b} tokens are {c}. Must some {a} tokens be {c}?", "No", "The stated overlap need not contain an A-group token."),
            (f"No {a} token is {b}. Token {c} is {b}. Could token {c} be {a}?", "No", "Membership in B excludes membership in A."),
            (f"Some {a} tokens are {b}. Every {b} token is {c}. Must some {a} tokens be {c}?", "Yes", "The existing overlap with B is also in C.")]
        prompt, answer, explanation = options[(tier+variant)%len(options)]
        return "set_deduction", prompt+" Answer Yes or No.", answer, explanation, "Distinguish what must be true from what could be true."
    if family == 5:
        people, colors = names[:3], RNG.sample(["RED","BLUE","GOLD","GREEN","VIOLET"],3)
        assignments = list(itertools.permutations(colors))
        secret = RNG.choice(assignments)
        predicates = [(i,color,equal) for i in range(3) for color in colors for equal in [True,False] if (secret[i]==color)==equal]
        RNG.shuffle(predicates)
        valid, clues = assignments[:], []
        for i,color,equal in predicates:
            kept = [p for p in valid if (p[i]==color)==equal]
            if len(kept)==len(valid): continue
            valid = kept
            clues.append(f"{people[i]} {'has' if equal else 'does not have'} {color}")
            if len(valid)==1: break
        assert valid == [secret]
        target = RNG.randrange(3)
        return ("assignment", f"{', '.join(people)} each have a different badge: {', '.join(colors)}. "+"; ".join(clues)+f". What colour does {people[target]} have?", secret[target],
                "; ".join(f"{p} has {c}" for p,c in zip(people,secret))+".", "Use each colour exactly once and eliminate forbidden assignments.")
    if family == 6:
        a,b,c,d = RNG.sample(range(2, 15+3*tier),4)
        if a+b==c+d: d+=1
        return ("route_choice", f"Two routes reach the exit. Through {names[0]}: {a} minutes then {b}. Through {names[1]}: {c} minutes then {d}. Which named node gives the quicker route?", names[0] if a+b<c+d else names[1],
                f"The route totals are {a+b} and {c+d} minutes.", "Compare the complete routes, not just their first segments.")
    if family == 7:
        small,difference = RNG.randint(3,30), RNG.randint(2,15)
        large=small+difference
        ask_large = (tier+variant)%2==0
        return ("balance_constraints", f"Two keys weigh {small+large} grams together. The heavier is {difference} grams heavier than the other. What does the {'heavier' if ask_large else 'lighter'} key weigh?", large if ask_large else small,
                f"The lighter key is ({small+large} - {difference}) / 2 = {small}; the heavier is {large}.", "Remove the extra weight first, then split the remaining weight equally.")
    if family == 8:
        directions = ["NORTH","EAST","SOUTH","WEST"]
        start = RNG.randrange(4)
        turns = [RNG.choice([-1,1,2]) for _ in range(2+tier)]
        words = {-1:"left",1:"right",2:"around"}
        return ("orientation", f"A drone faces {directions[start]}. It turns "+", then ".join(words[t] for t in turns)+". Left/right are quarter-turns; around is a half-turn. Which direction is it facing?", directions[(start+sum(turns))%4],
                f"The net turn is {sum(turns)%4} clockwise quarter-turns; it faces {directions[(start+sum(turns))%4]}.", "Track orientation after each turn; opposite turns cancel.")
    bits = [RNG.randrange(2) for _ in range(3)]
    # A fourth varying literal prevents the small 3-bit truth table repeating.
    threshold = RNG.randint(2, 90)
    test = threshold+RNG.choice([-1,1])
    a,b,c = bits
    answer = int(((a and b) or c) != (test>threshold))
    return ("boolean_gate", f"A={a}, B={b}, C={c}. Let D=1 if {test}>{threshold}, otherwise D=0. What is ((A AND B) OR C) XOR D? Enter 0 or 1.", answer,
            f"A AND B = {a and b}; OR C gives {(a and b) or c}; D={int(test>threshold)}. XOR gives {answer}.", "Evaluate the parentheses first. XOR is 1 only when its inputs differ.")


def memory(family, tier, variant):
    length = 4+tier
    sequence = RNG.sample(SYMBOLS,length)
    extra = {}
    if family == 0:
        pos = RNG.randrange(length)
        name,prompt,answer = "position_recall",f"Which symbol was in position {pos+1}?",sequence[pos]
        hint = "Count positions from the left, starting at 1."
    elif family == 1:
        sequence = [str(RNG.randrange(10)) for _ in range(3+tier)]
        name,prompt,answer = "reverse_digits","Enter the digits in reverse order, with no spaces.","".join(reversed(sequence))
        hint = f"The last digit was {sequence[-1]}; it becomes the first digit of the answer."
    elif family == 2:
        target=sequence[0]
        count=1+(tier+variant)%4
        sequence=[target]*count+RNG.sample([s for s in SYMBOLS if s!=target],length-count)
        RNG.shuffle(sequence)
        name,prompt,answer = "count_recall",f"How many times did {target} appear?",count
        hint="Scan the remembered positions once; repeated symbols each count."
    elif family == 3:
        name,prompt,answer = "edge_recall","Enter the first and last symbols separated by | (example: STAR|MOON).",sequence[0]+"|"+sequence[-1]
        hint=f"The first symbol was {sequence[0]}; recall the other edge."
    elif family == 4:
        pos=RNG.randrange(length-1)
        name,prompt,answer="adjacency_recall",f"What symbol came immediately after {sequence[pos]}?",sequence[pos+1]
        hint=f"{sequence[pos]} was in position {pos+1}; look one position to its right."
    elif family == 5:
        numbers=RNG.sample(range(10,40+10*tier),length)
        sequence=list(map(str,numbers))
        name,prompt,answer="maximum_recall","What was the largest number shown?",max(numbers)
        hint="Recall the largest tens digit first, then compare units if needed."
    elif family == 6:
        numbers=RNG.sample(range(1,30+5*tier),length)
        sequence=list(map(str,numbers))
        name,prompt,answer="parity_recall","How many of the numbers shown were even?",sum(n%2==0 for n in numbers)
        hint="Even numbers end in 0, 2, 4, 6, or 8."
    elif family == 7:
        sequence=RNG.sample(ALPHABET,3+tier)
        name,prompt,answer="alphabetic_recall","Enter the letters shown in alphabetical order, with no spaces.","".join(sorted(sequence))
        hint="Reorder the remembered letters; do not add letters that were absent."
    elif family == 8:
        missing=RNG.choice(sequence)
        shown=[s for s in sequence if s!=missing]
        RNG.shuffle(shown)
        name,prompt,answer="missing_recall","Which symbol from the original sequence is missing here? "+", ".join(shown),missing
        hint="Compare the remembered set against the remaining symbols. Order does not matter."
    else:
        numbers=RNG.sample(range(1,10+5*tier),length)
        sequence=list(map(str,numbers))
        name,prompt,answer="end_sum_recall","What is the sum of the first and last numbers shown?",numbers[0]+numbers[-1]
        hint="Recall only the two endpoints, then add them."
    stimulus="   ".join(sequence)
    extra.update(stimulus=stimulus,response_prompt=prompt,display_duration_seconds=round(max(2.2,4.8-tier*.35),2))
    explanation=f"The sequence was {' '.join(sequence)}. The answer is {answer}."
    return (name,prompt,answer,explanation,hint),extra


def attention(family, tier, variant):
    length=6+tier
    if family == 0:
        left="".join(RNG.choices(ALPHABET,k=length))
        pos=RNG.randrange(length)
        replacement=RNG.choice([s for s in ALPHABET if s!=left[pos]])
        right=left[:pos]+replacement+left[pos+1:]
        return ("mismatch",f"Find the single differing position, counting from 1. A: {left}   B: {right}",pos+1,
                f"Only position {pos+1} differs ({left[pos]} becomes {replacement}).","Compare aligned positions from left to right.")
    if family == 1:
        target=RNG.choice(ALPHABET)
        seq=RNG.choices([target,target]+RNG.sample([s for s in ALPHABET if s!=target],4),k=length+4)
        return ("character_count",f"How many {target} characters are in this code? {''.join(seq)}",seq.count(target),
                f"{target} occurs {seq.count(target)} times.","Count individual matching characters, including adjacent ones.")
    if family == 2:
        target=RNG.choice(["ON","OFF","ACK","NAK"])
        seq=RNG.choices(["ON","OFF","ACK","NAK"],k=length)
        return ("token_count",f"Count exact {target} tokens: {' '.join(seq)}",seq.count(target),
                f"There are {seq.count(target)} exact {target} tokens.","Treat each space-separated word as one token.")
    if family == 3:
        roots=RNG.sample(range(2,18+2*tier),length-1)
        values=[r*r for r in roots]
        odd=RNG.choice(roots)**2+1
        values.append(odd)
        RNG.shuffle(values)
        assert sum(math.isqrt(n)**2!=n for n in values)==1
        return ("non_square",f"One value is not a perfect square. Enter its position (from 1): {', '.join(map(str,values))}",values.index(odd)+1,
                f"{odd} is the only non-square, at position {values.index(odd)+1}.","Check values against nearby whole-number squares.")
    if family == 4:
        tokens=RNG.sample(SYMBOLS,length-1)
        duplicate=RNG.choice(tokens)
        tokens.append(duplicate)
        RNG.shuffle(tokens)
        return ("duplicate_token",f"Exactly one token appears twice. Which token? {' '.join(tokens)}",duplicate,
                f"{duplicate} occurs twice; every other token occurs once.","Mark tokens already seen while scanning left to right.")
    if family == 5:
        values=sorted(RNG.sample(range(1,60+10*tier),length))
        pos=RNG.randrange(length-1)
        values[pos],values[pos+1]=values[pos+1],values[pos]
        return ("order_break",f"At which position is a number first SMALLER than the number immediately before it? Count from 1: {', '.join(map(str,values))}",pos+2,
                f"Position {pos+2} contains {values[pos+1]}, below the preceding {values[pos]}.","Compare each number with its immediate predecessor.")
    if family == 6:
        threshold=RNG.randint(15,45)
        values=RNG.sample(range(1,70),length)
        answer=sum(n>threshold for n in values)
        return ("threshold_count",f"How many readings are STRICTLY greater than {threshold}? {', '.join(map(str,values))}",answer,
                f"Qualifying readings: {', '.join(str(n) for n in values if n>threshold) or 'none'}. Count: {answer}.","A reading equal to the threshold does not qualify.")
    if family == 7:
        upper=RNG.choice("ABDEGH")
        chars=RNG.choices([upper,upper.lower(),"x","X","o"],k=length+4)
        return ("case_sensitive_count",f"Count uppercase {upper} only (case matters): {''.join(chars)}",chars.count(upper),
                f"There are {chars.count(upper)} uppercase {upper} characters.","Ignore the lowercase version of the target letter.")
    if family == 8:
        values=RNG.sample(ALPHABET,3+tier)
        unique=values[0]
        seq=[unique]+[c for value in values[1:] for c in [value,value]]
        RNG.shuffle(seq)
        return ("unique_symbol",f"Every letter appears twice except one that appears once. Which letter? {' '.join(seq)}",unique,
                f"{unique} is the only letter without a matching partner.","Pair identical letters and find the unpaired one.")
    values=RNG.sample(range(2,15+2*tier),length)
    chosen=set(RNG.sample(range(length),2+variant))
    text=" ".join(f"[{n}]" if i in chosen else str(n) for i,n in enumerate(values))
    answer=sum(values[i] for i in chosen)
    return ("marked_sum",f"Add ONLY the numbers inside square brackets: {text}",answer,
            f"The bracketed values sum to {answer}.","Ignore all numbers without square brackets.")


def bosses():
    for family in range(6):
        for variant in range(10):
            a,b,c = RNG.randint(12,60),RNG.randint(3,12),RNG.randint(2,9)
            if family == 0:
                d=2*RNG.randint(2,10)
                answer=((a+b)*2*c-d)//2+a*c
                add("arithmetic","boss_nested",5,f"Calculate (({a} + {b}) x {2*c} - {d}) / 2 + {a} x {c}.",answer,
                    f"After halving the first part you have {(a+b)*c-d//2}; add {a*c} to get {answer}.","Evaluate the two products separately, then combine them.",boss=True)
            elif family == 1:
                price=400*a
                discount=RNG.choice([10,20,25,30,40])
                fee=RNG.choice([5,10,15,20])
                answer=price*(100-discount)*(100+fee)//10000
                assert price*(100-discount)*(100+fee)%10000==0
                add("arithmetic","boss_sequential_percent",5,f"A server costs {price} credits. Apply a {discount}% discount, then add a {fee}% fee to the discounted price. What is the final total?",answer,
                    f"Discounted price: {price*(100-discount)//100}. Applying the fee gives {answer}.","The fee uses the discounted price, not the original price.",boss=True)
            elif family == 2:
                total=a+b
                weighted=3*a+2*b
                add("arithmetic","boss_two_constraints",5,f"There are {total} tokens: gold tokens weigh 3 g and silver tokens weigh 2 g. Their total mass is {weighted} g. How many gold tokens are there?",a,
                    f"If all were silver, mass would be {2*total}. The extra {weighted-2*total} grams means {a} gold tokens.","Start with an all-silver baseline and count the extra grams.",boss=True)
            elif family == 3:
                odd=[b*c**i for i in range(4)]
                even=[a+i*(b+c) for i in range(4)]
                seq=[value for pair in zip(odd,even) for value in pair]
                add("patterns","boss_interleaved",5,f"Find the next number: {', '.join(map(str,seq[:-1]))}, ?",seq[-1],
                    f"Odd positions multiply by {c}; even positions add {b+c}. The next even-position value is {seq[-1]}.","Separate odd and even positions; they follow different rules.",boss=True)
            elif family == 4:
                seq=[b*n*n+a*n+c for n in range(1,7)]
                add("patterns","boss_second_difference",5,f"Find the next number: {', '.join(map(str,seq[:-1]))}, ?",seq[-1],
                    f"Second differences equal {2*b}. Continue the increasing first differences to reach {seq[-1]}.","Find the gaps, then find the gaps between those gaps.",boss=True)
            else:
                start=2*a
                # Explicit pipeline has no ambiguous integer division.
                answer=(start+b)*c-2*b
                add("arithmetic","boss_pipeline",5,f"A counter starts at {start}. Add {b}, multiply the result by {c}, then subtract twice the original addition. What is the final value?",answer,
                    f"({start}+{b}) x {c} - 2 x {b} = {answer}.","Keep the original addition available for the last step.",boss=True)


def build_bank():
    QUESTIONS.clear()
    SIGNATURES.clear()
    RNG.seed(20261021)
    generators={"arithmetic":arithmetic,"patterns":patterns,"logic":logic,"attention":attention}
    for category in ["arithmetic","patterns","logic","memory","attention"]:
        for family in range(10):
            for tier in range(1,6):
                for variant in range(2):
                    for attempt in range(200):
                        if category=="memory":
                            values,extra=memory(family,tier,variant)
                        else:
                            values,extra=generators[category](family,tier,variant),{}
                        name,prompt,answer,explanation,hint=values
                        signature=" ".join((prompt+"|"+extra.get("stimulus","")).lower().split())
                        if signature not in SIGNATURES: break
                    else: raise AssertionError(f"Could not make a unique {category}/{family}")
                    add(category,name,tier,prompt,answer,explanation,hint,**extra)
    bosses()
    # Expand arithmetic with five additional puzzle formats without perturbing existing IDs.
    for family in range(10,15):
        for tier in range(1,6):
            for variant in range(2):
                for attempt in range(200):
                    name,prompt,answer,explanation,hint=arithmetic(family,tier,variant)
                    signature=" ".join(prompt.lower().split())
                    if signature not in SIGNATURES: break
                else: raise AssertionError(f"Could not make a unique arithmetic/{family}")
                add("arithmetic",name,tier,prompt,answer,explanation,hint)
    assert len(QUESTIONS)==610
    assert len({q["id"] for q in QUESTIONS})==610
    regular=[q for q in QUESTIONS if not q["boss_eligible"]]
    assert Counter(q["category"] for q in regular)=={"arithmetic":150,"patterns":100,"logic":100,"memory":100,"attention":100}
    assert len({(q["category"],q["subcategory"]) for q in regular})==55
    assert all(len({q["answer"] for q in regular if q["category"]=="logic" and q["subcategory"]==family})>1 for family in {q["subcategory"] for q in regular if q["category"]=="logic"})
    for q in QUESTIONS:
        assert q["answer"] in q["accepted_answers"]
        assert all(q[k].strip() for k in ["prompt","explanation","intel_hint"])
        assert set(q["time_limits_by_exposure"])==set(SCALES)
        assert 1<=q["difficulty"]<=5
    return {"schema_version":3,"question_count":len(QUESTIONS),"questions":QUESTIONS}


if __name__ == "__main__":
    bank=build_bank()
    output=Path(__file__).resolve().parents[1]/"data"/"question_bank.json"
    output.write_text(json.dumps(bank,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print("Wrote 610 unique questions: 550 regular (150 arithmetic), 60 bosses, 55 regular puzzle families.")



