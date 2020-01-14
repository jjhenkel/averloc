package transforms;

import spoon.processing.AbstractProcessor;

import spoon.reflect.cu.*;
import spoon.reflect.cu.position.*;
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

public class Renamer<T extends CtNamedElement> extends AverlocTransformer {
  protected boolean debug = false;

  protected ArrayList<T> theDefs;
  protected ArrayList<T> targetDefs;

  protected ArrayList<String> subtokenBank;
  protected ArrayList<String> namesOfDefs;
  protected ArrayList<String> namesOfTargetDefs;

  protected void setDefs(ArrayList<T> defs) {
    theDefs = new ArrayList<T>(defs);
    namesOfDefs = new ArrayList<String>();

    for (T def : defs) {
      namesOfDefs.add(def.getSimpleName());
    }

    if (debug) {
      System.out.println(String.format(
        "[RENAMER] - Recieved %s defs.", defs.size()
      ));
      System.out.println(String.format(
        "[RENAMER] - Recieved %s def names.", namesOfDefs.size()
      ));
    }
  }

  protected void setSubtokens(ArrayList<String> subtokens) {
    subtokenBank = subtokens;

    if (debug) {
      System.out.println(String.format(
        "[RENAMER] - Recieved a corpus of %s frequent subtokens for random name building.",
        subtokenBank.size()
      ));
    }
  }

  protected void takePercentage(double percentage) {
    Collections.shuffle(theDefs);

    int toTake = (int)Math.floor(theDefs.size() * percentage);

    if (toTake <= 0) {
      if (debug) {
        System.out.println("[RENAMER] - Note: zero defs selected for transform.");
      }
      return;
    }

    targetDefs = new ArrayList<T>(theDefs.subList(0, toTake));
    namesOfTargetDefs = new ArrayList<String>();

    for (T targetDef : targetDefs) {
      namesOfTargetDefs.add(targetDef.getSimpleName());
    }

    if (debug) {
      System.out.println(String.format(
        "[RENAMER] - Selecting %s%% (%s) of defs.", percentage*100.0, toTake
      ));
    }
  }

  protected IdentityHashMap<T, String> generateRenaming(boolean shuffle, int nameMinSubtokens, int nameMaxSubtokens) {
    IdentityHashMap<T, String> renames = new IdentityHashMap<T, String>();
    
    if (targetDefs == null || targetDefs.size() <= 0) {
      if (debug) {
        System.out.println("[RENAMER] - No renaming to be done: no targets selected.");
      }
      return null;
    }

    if (debug) {
      if (shuffle) {
        System.out.println("[RENAMER] - Generating renaming: mode=SHUFFLE.");
      } else {
        System.out.println(String.format(
          "[RENAMER] - Generating renaming: mode=RANDOM; nameMinSubtokens=%s; nameMaxSubtokens=%s.",
          nameMinSubtokens, nameMaxSubtokens
        ));
      }
    }

    if (shuffle) {
      if (targetDefs.size() <= 1) {
        if (debug) {
          System.out.println(String.format(
            "[RENAMER] - Cannot use shuffle mode with %s targets.", targetDefs.size()
          ));
        }
        return null;
      }

      Random rshuf = new Random();

      // Keep shuffling till we don't assign any name to itself
      // This generates a derangement but it's slow (~3x compared to 
      // just a permutation in this implementation) so maybe let's 
      // use some tricks to get (non-uniform) random (near) derangements?
      // boolean validShuffle = false;
      // while (!validShuffle) {
        // validShuffle = true;
      Collections.shuffle(namesOfTargetDefs);
      for (int i = 0; i < targetDefs.size(); i++) {
          if (namesOfTargetDefs.get(i).equals(targetDefs.get(i).getSimpleName())) {
              Collections.swap(
                namesOfTargetDefs, 
                i,
                rshuf.nextInt(namesOfTargetDefs.size() - 1)
              );
          }
      }
      // }

      // Setup those renames now that we have a good shuffle
      for (int i = 0; i < targetDefs.size(); i++) {
        renames.put(targetDefs.get(i), namesOfTargetDefs.get(i));
      }
    } else {
      Random rand = new Random();
      for (T target : targetDefs) {
        Collections.shuffle(subtokenBank);

        int length = 0;
        String name = null;
        do {
          length = rand.nextInt((nameMaxSubtokens - nameMinSubtokens) + 1) + nameMinSubtokens;
          name = camelCased(subtokenBank.subList(0, length));
          // TODO: maybe make sure we don't use any subtokens in the function's name?
          // This (maybe) removes the possibility of us accidentally helping the model?
        } while (namesOfDefs.contains(name)); // Make sure we don't clash with pre-existing name

        renames.put(target, name);
      }
    }

    if (debug) {
      System.out.println("[RENAMER] - Generated renaming:");
      for (Map.Entry<T,String> item : renames.entrySet()) {
        System.out.println(String.format(
          "[RENAMER]   + Renamed: %s ==> %s.", item.getKey().getSimpleName(), item.getValue()
        ));
      }
    }

    return renames;
  }

  protected String safeGetLine(CtElement element) {
    SourcePosition position = element.getPosition();

    if (position instanceof NoSourcePosition) {
      return "???";
    } else {
      return String.format("%s", position.getLine());
    }
  }

  protected void applyRenaming(CtExecutable method, boolean skipDecls, IdentityHashMap<T, String> renames) {
    ArrayList<CtVariableAccess> usages = getChildrenOfType(method, CtVariableAccess.class);

    if (debug) {
      System.out.println("[RENAMER] - Applying renaming:");
    }

    if (renames == null) {
      if (debug) {
        System.out.println("[RENAMER]   + No renames provided: stopping.");
      }
      return;
    }

    for (CtVariableAccess usage : usages) {
      CtVariableReference<?> reference = usage.getVariable();
      if (reference != null) {
        CtNamedElement theDecl = reference.getDeclaration();
        if (renames.containsKey(theDecl)) {
          if (debug) {
            System.out.println(String.format(
              "[RENAMER]   + Applied renaming (%s ==> %s) to ref at line %s.",
              theDecl.getSimpleName(), renames.get(theDecl), safeGetLine(usage)
            ));
          }

          reference.setSimpleName(renames.get(theDecl));
          this.setChanged(method);
        }
      }
    }

    if (skipDecls) {
      if (debug) {
        System.out.println(String.format(
          "[RENAMER]   + Skipping decls."
        ));
      }
      return;
    }

    for (Map.Entry<T,String> item : renames.entrySet()) {
      if (debug) {
        System.out.println(String.format(
          "[RENAMER]   + Applied renaming (%s ==> %s) to decl at line %s.",
          item.getKey().getSimpleName(), item.getValue(), safeGetLine(item.getKey())
        ));
      }

      item.getKey().setSimpleName(item.getValue());
      this.setChanged(method);
    }
  }
}
