import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import java.util.zip.ZipFile;
import org.objectweb.asm.ClassReader;
import org.objectweb.asm.ClassVisitor;
import org.objectweb.asm.ClassWriter;
import org.objectweb.asm.MethodVisitor;
import org.objectweb.asm.Opcodes;

public class PatchSliderNumber {
    public static void main(String[] args) throws Exception {
        final Set<String> targets = new HashSet<String>(Arrays.asList(
                "getSlider", "getSliderMin", "getSliderMax", "getSliderInterval"));
        final int[] castCount = {0};
        final int[] callCount = {0};
        try (ZipFile jar = new ZipFile(args[0]);
             InputStream source = jar.getInputStream(jar.getEntry("xyz/daikirai/script/ScriptDefaults$modules.class"))) {
            ClassReader reader = new ClassReader(source);
            ClassWriter writer = new ClassWriter(reader, 0);
            reader.accept(new ClassVisitor(Opcodes.ASM9, writer) {
                @Override
                public MethodVisitor visitMethod(int access, String name, String descriptor, String signature, String[] exceptions) {
                    MethodVisitor out = super.visitMethod(access, name, descriptor, signature, exceptions);
                    if (!targets.contains(name) || !descriptor.equals("(Ljava/lang/String;Ljava/lang/String;)D")) {
                        return out;
                    }
                    return new MethodVisitor(Opcodes.ASM9, out) {
                        @Override
                        public void visitTypeInsn(int opcode, String type) {
                            if (opcode == Opcodes.CHECKCAST && type.equals("java/lang/Double")) {
                                type = "java/lang/Number";
                                castCount[0]++;
                            }
                            super.visitTypeInsn(opcode, type);
                        }

                        @Override
                        public void visitMethodInsn(int opcode, String owner, String method, String desc, boolean isInterface) {
                            if (opcode == Opcodes.INVOKEVIRTUAL && owner.equals("java/lang/Double")
                                    && method.equals("doubleValue") && desc.equals("()D")) {
                                owner = "java/lang/Number";
                                callCount[0]++;
                            }
                            super.visitMethodInsn(opcode, owner, method, desc, isInterface);
                        }
                    };
                }
            }, 0);
            if (castCount[0] != 4 || callCount[0] != 4) {
                throw new IllegalStateException("Unexpected slider bytecode: casts=" + castCount[0] + ", calls=" + callCount[0]);
            }
            Files.write(Paths.get(args[1]), writer.toByteArray());
            System.out.println("Patched four numeric slider getters.");
        }
    }
}
