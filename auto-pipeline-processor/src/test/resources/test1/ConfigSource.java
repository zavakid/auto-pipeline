package test1;

import com.foldright.auto.pipeline.AutoPipeline;

@AutoPipeline
public interface ConfigSource {
    String get(String name);
}
