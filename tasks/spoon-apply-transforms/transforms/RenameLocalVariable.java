package transforms;

import spoon.processing.AbstractProcessor;

import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

import spoon.reflect.visitor.CtIterator;

import java.util.*;
import java.util.stream.*;
import java.nio.file.Paths;
import java.nio.file.Files;
import java.io.IOException;
import java.lang.Math;

public class RenameLocalVariable extends AbstractProcessor<CtExecutable> {

    // Parameters to the renaming transform
    final static int NAME_MIN_LENGTH = 1;
    final static int NAME_MAX_LENGTH = 5;
    final static double RENAME_PERCENT = 0.50;
    final static Boolean SHUFFLE_MODE = false;
    final static int USE_TOP_N_SUBTOKENS = 100;

    static ArrayList<String> TOP_N_SUBTOKENS;

    static
    {
        // Load the top tokens once
        try (Stream<String> lines = Files.lines(Paths.get("/histo.txt"))) {
            TOP_N_SUBTOKENS = new ArrayList<String>(
                lines.limit(USE_TOP_N_SUBTOKENS).collect(Collectors.toList())
            );
        } catch (IOException ex) { }
    }

    // Build a camel cased name from a randomized sub-token list
    private String camelCased(List<String> inputs) {
        String retVal = inputs.get(0);
        for (String part : inputs.subList(1, inputs.size())) {
            retVal += part.substring(0, 1).toUpperCase() + part.substring(1);
        }
        return retVal;
    }

	@Override
	public void process(CtExecutable element) {
        // Skip this 
        if (element.getSimpleName().equals("<init>")) {
			return;
        }
        
        // Also skip nested things...
        if (!((CtTypeMember)element).getDeclaringType().getSimpleName().equals("WRAPPER")) {
            return;
        }

        Random rand = new Random();

        // Keep a collection of CtLocalVariables
        // (That is, find all of the local variable decls and save them into an array for later use.)
        ArrayList<CtLocalVariable> localVarDefs = new ArrayList<CtLocalVariable>();
        CtIterator iterator1 = new CtIterator(element);
        while (iterator1.hasNext()) {
            CtElement el = iterator1.next();
            if (el instanceof CtLocalVariable) {
                localVarDefs.add((CtLocalVariable)el);
            }
        }

        // Shuffle the list and take the first X% of items
        Collections.shuffle(localVarDefs);
        int take = (int)Math.floor(localVarDefs.size() * RENAME_PERCENT);
        ArrayList<CtLocalVariable> renameThese = new ArrayList<CtLocalVariable>();
        if (take > 0) {
            renameThese = new ArrayList<CtLocalVariable>(localVarDefs.subList(0, take));
        }

        // Rename them at random (two modes: shuffle, use top-K)
        HashMap<CtLocalVariable, String> renames = new HashMap<CtLocalVariable, String>();

        // TODO: support shuffle mode
        if (!SHUFFLE_MODE) {
            for (CtLocalVariable var : renameThese) {
                // Shuffle top tokens
                Collections.shuffle(TOP_N_SUBTOKENS);

                // Pick a random number of subtokens
                int subLen = rand.nextInt((NAME_MAX_LENGTH - NAME_MIN_LENGTH) + 1) + NAME_MIN_LENGTH;
                
                // Generate a name of random length using a random subset of the top N target sub tokens
                // in the corpus
                String newName = camelCased(TOP_N_SUBTOKENS.subList(0, subLen));
                
                // Save that renaming into our map
                renames.put(var, newName);
            }
        }

        // Update appropriate references
        CtIterator iterator2 = new CtIterator(element);
        while (iterator2.hasNext()) {
            CtElement el = iterator2.next();
            if (el instanceof CtVariableAccess) {
                CtVariableReference<?> theVariable = ((CtVariableAccess)el).getVariable();
                if (theVariable != null) {
                    CtNamedElement theDecl = theVariable.getDeclaration();
                    if (renameThese.contains(theDecl)) {
                        // Actually rename the reference 
                        theVariable.setSimpleName(renames.get(theDecl));
                    }
                }
            }
        }

        // Update decls
        for (CtLocalVariable var : renameThese) {
            // Actually rename the decl
            var.setSimpleName(renames.get(var));
        }
	}
}
