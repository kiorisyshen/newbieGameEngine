#pragma once
#include <map>
#include <string>
#include <vector>
#include "SceneObject.hpp"
#include "Tree.hpp"
#include "geommath.hpp"

namespace newbieGE {
class BaseSceneNode : public TreeNode {
   protected:
    std::string m_strName;
    std::vector<std::shared_ptr<SceneObjectTransform>> m_Transforms;
    std::map<int, std::shared_ptr<SceneObjectAnimationClip>> m_AnimationClips;
    std::map<std::string, std::shared_ptr<SceneObjectTransform>> m_LUTtransform;
    Matrix4X4f m_RuntimeTransform;

   public:
    typedef std::map<int, std::shared_ptr<SceneObjectAnimationClip>>::const_iterator animation_clip_iterator;

   public:
    BaseSceneNode() {
        BuildIdentityMatrix(m_RuntimeTransform);
    };
    BaseSceneNode(const std::string &name) {
        m_strName = name;
        BuildIdentityMatrix(m_RuntimeTransform);
    };
    virtual ~BaseSceneNode(){};

    const std::string GetName() const {
        return m_strName;
    };

    void AttachAnimationClip(int clip_index, std::shared_ptr<SceneObjectAnimationClip> clip) {
        m_AnimationClips.insert({clip_index, clip});
    }

    inline bool GetFirstAnimationClip(animation_clip_iterator &it) {
        it = m_AnimationClips.cbegin();
        return it != m_AnimationClips.cend();
    }

    inline bool GetNextAnimationClip(animation_clip_iterator &it) {
        it++;
        return it != m_AnimationClips.cend();
    }

    void AppendTransform(const char *key, const std::shared_ptr<SceneObjectTransform> &transform) {
        m_Transforms.push_back(transform);
        m_LUTtransform.insert({std::string(key), transform});
    }

    std::shared_ptr<SceneObjectTransform> GetTransform(const std::string &key) {
        auto it = m_LUTtransform.find(key);
        if (it != m_LUTtransform.end()) {
            return it->second;
        } else {
            return std::shared_ptr<SceneObjectTransform>();
        }
    }

    const std::shared_ptr<Matrix4X4f> GetCalculatedTransform() const {
        std::shared_ptr<Matrix4X4f> result(new Matrix4X4f());
        BuildIdentityMatrix(*result);

        // TODO: cascading calculation
        for (auto it = m_Transforms.rbegin(); it != m_Transforms.rend(); it++) {
            *result = *result * static_cast<Matrix4X4f>(**it);
        }

        // apply runtime transforms
        *result = *result * m_RuntimeTransform;

        return result;
    }

    void RotateBy(float rotation_angle_x, float rotation_angle_y, float rotation_angle_z) {
        Matrix4X4f rotate;
        MatrixRotationYawPitchRoll(rotate, rotation_angle_x, rotation_angle_y, rotation_angle_z);
        m_RuntimeTransform = m_RuntimeTransform * rotate;
    }

    void RotateBy(const Vector3f &axis, const float angle) {
        Matrix3X3f pitch3;
        MatrixRotationVectorAngle(pitch3, axis, angle);

        Matrix4X4f pitch4 = {{{pitch3[0].data[0], pitch3[0].data[1], pitch3[0].data[2], 0.0},
                              {pitch3[1].data[0], pitch3[1].data[1], pitch3[1].data[2], 0.0},
                              {pitch3[2].data[0], pitch3[2].data[1], pitch3[2].data[2], 0.0},
                              {0.0, 0.0, 0.0, 1.0}}};

        Vector3f up = GetLocalAxis()[1];
        TransformCoord(up, m_RuntimeTransform * pitch4);
        if (up.data[2] > 0.01) {  // forbid over rotation
            m_RuntimeTransform = m_RuntimeTransform * pitch4;
        }
    }

    void MoveBy(float distance_x, float distance_y, float distance_z) {
        Matrix4X4f translation;
        MatrixTranslation(translation, distance_x, distance_y, distance_z);
        m_RuntimeTransform = m_RuntimeTransform * translation;
    }

    void MoveBy(const Vector3f &distance) {
        MoveBy(distance[0], distance[1], distance[2]);
    }

    virtual Matrix3X3f GetLocalAxis() {
        return {{{1.0f, 0.0f, 0.0f},
                 {0.0f, 1.0f, 0.0f},
                 {0.0f, 0.0f, 1.0f}}};
    }

    friend std::ostream &operator<<(std::ostream &out, const BaseSceneNode &node) {
        static thread_local int32_t indent = 0;
        indent++;

        out << std::string(indent, ' ') << "Scene Node" << std::endl;
        out << std::string(indent, ' ') << "----------" << std::endl;
        out << std::string(indent, ' ') << "Name: " << node.m_strName << std::endl;
        node.dump(out);
        out << std::endl;

        for (auto sub_node : node.m_Children) {
            out << *sub_node << std::endl;
        }

        for (auto trans : node.m_Transforms) {
            out << *trans << std::endl;
        }

        for (auto anim_clip : node.m_AnimationClips) {
            out << *anim_clip.second << std::endl;
        }

        indent--;

        return out;
    }
};

template <typename T>
class SceneNode : public BaseSceneNode {
   protected:
    std::string m_keySceneObject;

   protected:
    virtual void dump(std::ostream &out) const {
        out << m_keySceneObject << std::endl;
    };

   public:
    using BaseSceneNode::BaseSceneNode;
    SceneNode() = default;

    void AddSceneObjectRef(const std::string &key) {
        m_keySceneObject = key;
    };

    const std::string &GetSceneObjectRef() {
        return m_keySceneObject;
    };
};

typedef BaseSceneNode SceneEmptyNode;

}  // namespace newbieGE
