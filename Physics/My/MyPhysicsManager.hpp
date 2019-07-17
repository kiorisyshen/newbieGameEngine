#pragma once
#include "IPhysicsManager.hpp"
#include "Geometry.hpp"

namespace newbieGE
{
class MyPhysicsManager : public IPhysicsManager
{
public:
    int Initialize() override;
    void Finalize() override;
    void Tick() override;

    void CreateRigidBody(SceneGeometryNode &node, const SceneObjectGeometry &geometry) override;
    void DeleteRigidBody(SceneGeometryNode &node) override;

    int CreateRigidBodies() override;
    void ClearRigidBodies() override;

    Matrix4X4f GetRigidBodyTransform(void *rigidBody) override;
    void UpdateRigidBodyTransform(SceneGeometryNode &node) override;

    void ApplyCentralForce(void *rigidBody, Vector3f force) override;

#ifdef DEBUG
    void DrawDebugInfo() override;
#endif

protected:
#ifdef DEBUG
    void DrawAabb(const Geometry &geometry, const Matrix4X4f &trans, const Vector3f &centerOfMass);
#endif
};
} // namespace newbieGE
